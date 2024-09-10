require 'jekyll'
require 'nokogiri'

module Jekyll
    class CustomConverter < Converter
        safe true
        priority :low

        @@total_conversion_time = 0

        def matches(ext)
            ext = ext.downcase
            ext == ".md" || ext == ".markdown"
        end

        def output_ext(ext)
            ".html"
        end

        def convert(content)
            start_time = Time.now

            doc = Nokogiri::HTML::DocumentFragment.parse(content)

            decorate_links(doc)
            decorate_toc(doc)

            @@total_conversion_time += Time.now - start_time

            doc.to_html
        end

        def decorate_links(doc)
            doc.css('a').each do |link|
                if link['href'] =~ /wikipedia\.org/ || link['href'] =~ /wikimedia\.org/ || link['href'] =~ /wiktionary\.org/ || link['href'] =~ /wikisource\.org/
                    link['class'] = (link['class'].to_s.split(' ') << 'link-wikipedia').join(' ')
                elsif link['href'] =~ /archive\.org/
                    link['class'] = (link['class'].to_s.split(' ') << 'link-archive').join(' ')
                elsif link['href'] =~ %r{^https?://[^/]+/@[\w_]+}
                    link['class'] = (link['class'].to_s.split(' ') << 'link-mastodon').join(' ')
                elsif link['href'].start_with?('http://', 'https://')
                    link['class'] = (link['class'].to_s.split(' ') << 'link-external').join(' ')
                end
            end
        end

        def decorate_toc(doc)
            toc_element = doc.at_css('.toc')
            return unless toc_element

            toc = []
            toc_ids = 0

            doc.css('h1[id^="heading-"],h2[id^="heading-"],h3[id^="heading-"],h4[id^="heading-"],h5[id^="heading-"],h6[id^="heading-"]').each do |heading|
                heading_classes = heading['class'].to_s.split(' ')

                next if heading_classes.include?('no-toc')

                heading['class'] = (heading_classes << 'heading').join(' ')
                level = heading.name[1].to_i
                id = heading['id']
                text = heading.text
                toc_entry_id = "toc-#{toc_ids += 1}"

                heading_back_link = " <a href='##{toc_entry_id}' class='toc-back-link'>↩</a>"
                heading.add_child(heading_back_link)

                toc << { level: level, id: id, text: text, toc_entry_id: toc_entry_id }
            end

            toc.each do |entry|
                level = entry[:level]
                id = entry[:id]
                text = entry[:text]
                toc_entry_id = entry[:toc_entry_id]

                link = "<a href='##{id}'>#{text}</a>"
                entry_html = "<p id='#{toc_entry_id}' class='toc toc-h#{level}'>#{link}</p>"
                toc_element.add_child(entry_html)
            end
        end

        def self.total_conversion_time
            @@total_conversion_time
        end
    end

    class TOCTag < Liquid::Tag
        def render(context)
            '<div class="toc"></div>'
        end
    end
end

Jekyll::Hooks.register :site, :post_render do |site|
    Jekyll.logger.info "DOM Decorator", "Decorated in #{Jekyll::CustomConverter.total_conversion_time.round(2)} seconds"
end

Liquid::Template.register_tag('toc', Jekyll::TOCTag)

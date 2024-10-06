require 'nokogiri'
require 'tempfile'
require 'open3'

module Jekyll
    class DomConverter < Converter
        safe true
        priority :low

        @@total_conversion_time = 0
        @@current_post = nil

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
            decorate_headings(doc)
            decorate_mermaid(doc)

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

        def decorate_headings(doc)
            toc_element = doc.at_css('.toc')
            automatic_toc = @@current_post && !!@@current_post.data['toc']

            maxdepth = 6
            if toc_element && toc_element['data-maxdepth']
                maxdepth = toc_element['data-maxdepth'].to_i
                maxdepth = 6 if maxdepth > 6
                toc_element.remove_attribute('data-maxdepth')
            end

            toc = []
            toc_ids = 0

            doc.css('h1[id^="heading-"],h2[id^="heading-"],h3[id^="heading-"],h4[id^="heading-"],h5[id^="heading-"],h6[id^="heading-"]').each do |heading|
                heading_classes = heading['class'].to_s.split(' ')

                next if heading_classes.include?('no-toc')

                id = heading['id']
                level = heading.name[1].to_i
                text = heading.text

                anchor = "<a class='heading-link' href='##{id}'>§</a>"
                heading.prepend_child(anchor)

                next if level > maxdepth

                heading['class'] = (heading_classes << 'heading').join(' ')
                toc_entry_id = "toc-#{toc_ids += 1}"

                if toc_element
                    heading_back_link = " <a href='##{toc_entry_id}' class='toc-back-link'>↩</a>"
                    heading.add_child(heading_back_link)
                end

                toc << { level: level, id: id, text: text, toc_entry_id: toc_entry_id }
            end

            Jekyll.logger.warn "DOM Decorator", "No headings found in the document #{@@current_post.data["title"]}" if toc.empty? && (automatic_toc || toc_element)

            @@current_post.data["toc_html"] = "" if automatic_toc

            toc.each do |entry|
                level = entry[:level]
                id = entry[:id]
                text = entry[:text]
                toc_entry_id = entry[:toc_entry_id]

                link = "<a href=\"##{id}\">#{text}</a>"

                if toc_element
                    entry_html = "<p id=\"#{toc_entry_id}\" class=\"toc toc-h#{level}\">#{link}</p>"
                    toc_element.add_child(entry_html)
                end
                if automatic_toc
                    entry_html = "<p class=\"toc toc-h#{level}\">#{link}</p>"
                    @@current_post.data["toc_html"] << entry_html
                end
            end
        end

        def decorate_mermaid(doc)
            cache_dir = File.join(@@current_post.site.in_source_dir, '.jekyll-cache', 'dom-decorator') if @@current_post

            doc.css('pre.mermaid').each_with_index do |code, index|
                text = code.text.strip

                svg_unique_id = Digest::MD5.hexdigest(text)

                svg_content = if cache_dir
                    svg_file_cache_path = File.join(cache_dir, "#{svg_unique_id}.svg")
                    if File.exist?(svg_file_cache_path)
                        Jekyll.logger.debug "DOM Decorator", "Using cached Mermaid SVG ##{index} in URL #{@@current_post.url}"

                        File.read(svg_file_cache_path)
                    else
                        svg_content = mermaid_to_svg(text, index, svg_unique_id)
                        FileUtils.mkdir_p(cache_dir)
                        File.write(svg_file_cache_path, svg_content)
                        svg_content
                    end
                else
                    mermaid_to_svg(text, index, svg_unique_id)
                end

                code.replace("<div class=\"mermaid\"><!--\n#{text}\n-->\n#{svg_content}</div>")
            end
        end

        def mermaid_to_svg(text, index, id)
            Tempfile.create(['mermaid', '.mmd']) do |file|
                file.write(text)
                file.flush

                svg_path = file.path.sub(/\.mmd$/, '.svg')
                begin
                    Jekyll.logger.info "DOM Decorator", "Generating Mermaid SVG ##{index} in URL #{@@current_post.url}"
                    _stdout, stderr, status = Open3.capture3("mmdc --svgId svg#{id} -i #{file.path} -o #{svg_path}")
                    raise "Mermaid conversion failed for content: #{stderr}" unless status.success?

                    return File.read(svg_path)
                ensure
                    File.delete(svg_path) if File.exist?(svg_path)
                end
            end
        end

        def self.total_conversion_time
            @@total_conversion_time
        end

        def self.set_current_post(post)
            @@current_post = post
        end
    end

    class TOCTag < Liquid::Tag
        def initialize(tag_name, text, tokens)
            super
            @params = {}
            text.scan(Liquid::TagAttributes) do |key, value|
                if key == "maxdepth"
                    value = value.to_i
                else
                    raise "Invalid syntax for TOC tag" if key.empty? || value.empty? || key != "maxdepth"
                end
                @params[key] = value
            end
        end

        def render(context)
            page = context.registers[:page]

            if page['_toc_rendered']
                raise "Error: Multiple TOC tags rendered in the same page"
            else
                page['_toc_rendered'] = true
            end

            if @params['maxdepth']
                "<div class=\"toc\" data-maxdepth=\"#{@params['maxdepth']}\"></div>"
            else
                "<div class=\"toc\"></div>"
            end
        end
    end
end

Jekyll::Hooks.register :posts, :pre_render do |post, payload|
    # Set the current post in a global variable of the converter, so it can access the post data
    Jekyll::DomConverter.set_current_post(post)
end

Jekyll::Hooks.register :posts, :post_render do |post|
    # Reset the current post after the conversion is done
    Jekyll::DomConverter.set_current_post(nil)
end

Jekyll::Hooks.register :site, :post_render do |site|
    Jekyll.logger.info "DOM Decorator", "Decorated in #{Jekyll::DomConverter.total_conversion_time.round(2)} seconds"
end

Liquid::Template.register_tag('toc', Jekyll::TOCTag)

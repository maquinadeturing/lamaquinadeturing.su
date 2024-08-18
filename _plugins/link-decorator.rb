require 'jekyll'
require 'nokogiri'

module Jekyll
    module LinkDecorator
        class WikipediaLinkDecorator
        def self.decorate(content)
            doc = Nokogiri::HTML.parse(content)
            doc.css('a').each do |link|
                if link['href'] =~ /wikipedia\.org/
                    link['class'] = (link['class'].to_s.split(' ') << 'link-wikipedia').join(' ')
                elsif link['href'] =~ /archive\.org/
                    link['class'] = (link['class'].to_s.split(' ') << 'link-archive').join(' ')
                elsif link['href'].start_with?('http://', 'https://')
                    link['class'] = (link['class'].to_s.split(' ') << 'link-external').join(' ')
                end
            end
            doc.to_s
        end
        end
    end
end

Jekyll::Hooks.register :posts, :post_render do |post|
  post.output = Jekyll::LinkDecorator::WikipediaLinkDecorator.decorate(post.output)
end

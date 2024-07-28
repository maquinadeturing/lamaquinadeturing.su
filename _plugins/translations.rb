require 'securerandom'
require 'set'

module Localization
    class LanguageGenerator < Jekyll::Generator
        safe true

        def generate(site)
            # Define an empty map
            post_groups = {}
            languages = site.config['languages']

            site.posts.docs.each do |post|
                unless post['lang']
                    if post.path =~ %r{_posts/(\w{2})/}
                        post.data['lang'] = $1
                    end
                end

                # Group posts by their 'uuid' property. If the 'uuid' property is not defined, generate a random one
                uuid = post['uuid'] || SecureRandom.uuid

                # Assign the 'uuid' property to the post
                post.data['uuid'] = uuid

                # Add the post to the set
                post_groups[uuid] = post.date
            end

            # Assign the keys of the post_groups map to site.data['localized_posts'] as an array sorted by date
            site.data['localized_posts'] = (post_groups.keys.sort_by { |uuid| post_groups[uuid] }).reverse

            # Generate the index pages for each language
            languages.each do |lang|
                site.config['defaults'] ||= []
                site.config['defaults'] << {
                    'scope' => { 'path' => "_posts/#{lang}", 'type' => 'posts' },
                    'values' => { 'permalink' => "#{lang}/:year/:month/:title/", 'lang' => lang }
                }
                site.pages << LanguagePage.new(site, lang)
            end
        end
    end

    # Subclass of `Jekyll::Page` with custom method definitions.
    class LanguagePage < Jekyll::Page
        def initialize(site, lang)
            @site = site             # the current site instance.
            @base = site.source      # path to the source directory.
            @dir  = lang             # the directory the page will reside in.

            # All pages have the same filename, so define attributes straight away.
            @basename = 'index'      # filename without the extension.
            @ext      = '.html'      # the extension.
            @name     = 'index.html' # basically @basename + @ext.

            @data = {
                'layout' => 'home',
                'lang' => lang,
            }

            data.default_proc = proc do |_, key|
                site.frontmatter_defaults.find(relative_path, :categories, key)
            end
        end

        # Placeholders that are used in constructing page URL.
        def url_placeholders
            {
                :path       => @dir,
                :lang       => @dir,
                :basename   => basename,
                :output_ext => output_ext,
            }
        end
    end
end

module Jekyll
    module LocalizationFilter
        def translations(uuid, lang = nil)
            languages = @context.registers[:site].config['languages']
            translations = @context.registers[:site].posts.docs.select { |p| p['uuid'] == uuid && (lang.nil? || p['lang'] != lang) }
            translations.sort_by { |p| languages.index(p['lang']) || languages.size }
        end

        def localize(string, lang)
            return string if lang.nil?
            @context.registers[:site].data['localization'][string][lang] || string
        end

        def find_prefered_translation(uuid, prefered_lang)
            # If the post is in the desired language, return it
            post = @context.registers[:site].posts.docs.find { |p| p['uuid'] == uuid && p['lang'] == prefered_lang }
            return post if post

            # If the post is not in the desired language, return a translation following the order of the languages array
            languages = @context.registers[:site].config['languages']
            for language in languages
                post = @context.registers[:site].posts.docs.find { |p| p['uuid'] == uuid && p['lang'] == language }
                return post if post
            end
        end

        def localized_date(date, format, lang)
            if lang == 'ca' then
                catalan_months_long = %w[gener febrer març abril maig juny juliol agost setembre octubre novembre desembre]
                catalan_months_short = %w[gen feb mar abr mai jun jul ago set oct nov des]
                if format.include? '%B' then
                    month_number = date.strftime('%m').to_i
                    format = format.gsub('%B', catalan_months_long[month_number - 1])
                end
                if format.include? '%b' then
                    month_number = date.strftime('%m').to_i
                    format = format.gsub('%b', catalan_months_short[month_number - 1])
                end
            elsif lang == 'es' then
                spanish_months_long = %w[enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre]
                spanish_months_short = %w[ene feb mar abr may jun jul ago sep oct nov dic]
                if format.include? '%B' then
                    month_number = date.strftime('%m').to_i
                    format = format.gsub('%B', spanish_months_long[month_number - 1])
                end
                if format.include? '%b' then
                    month_number = date.strftime('%m').to_i
                    format = format.gsub('%b', spanish_months_short[month_number - 1])
                end
            end

            @context.invoke('date', date, format)
        end
    end

    module TranslationTags
        class LinkUuidTag < Liquid::Tag
            def initialize(tag_name, input, tokens)
                super
                Jekyll.logger.info "LinkUuidTag: #{input}"

                # Param is a word and value is a string enclosed in single quotes or a word without spaces
                param_pattern = /\s*(\w+)=('[^']+'|[^ ]+)\s*/

                # Match all the param=value pairs in the input string, there can be more than one like `param1=value1 param2=value2`
                match = input.scan(param_pattern)

                # Verify that the matched parameters are exactly `title` and `uuid`
                raise 'Invalid tag parameters, expected title and uuid' if match.map { |m| m[0] }.to_set != ['title', 'uuid'].to_set

                # Assign the values to instance variables, removing the single quotes if present
                @title = match.find { |m| m[0] == 'title' }[1].gsub("'", '')
                @uuid = match.find { |m| m[0] == 'uuid' }[1].gsub("'", '')
            end

            def render(context)
                include_tag = "{% include link.html title='#{@title}' post_uuid='#{@uuid}' %}"
                parsed_tag = Liquid::Template.parse(include_tag)
                parsed_tag.render(context)
            end
        end
    end

    module RaiseError
        class RaiseTag < Liquid::Tag
            def initialize(tag_name, text, tokens)
                super
                # Jekyll.logger.info "AssertDefinedTag: #{value}"
                @text = text
            end

            def render(context)
                raise @text
            end
        end
    end
end

Liquid::Template.register_filter(Jekyll::LocalizationFilter)
Liquid::Template.register_tag('raise', Jekyll::RaiseError::RaiseTag)
Liquid::Template.register_tag('link_uuid', Jekyll::TranslationTags::LinkUuidTag)

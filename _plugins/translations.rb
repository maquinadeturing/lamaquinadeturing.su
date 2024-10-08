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
                        if post.data['layout'].nil? then
                            post.data['layout'] = 'post'
                        end
                    end
                end

                # Group posts by their 'uuid' property. If the 'uuid' property is not defined, generate a random one
                uuid = post['uuid'] || SecureRandom.uuid

                # Assign the 'uuid' property to the post
                post.data['uuid'] = uuid
                post.data['permalink'] = "/#{post['lang']}/:year/:month/:title/"

                # Add the post to the set
                post_groups[uuid] = post.date
            end

            # Assign the keys of the post_groups map to site.data['localized_posts'] as an array sorted by date
            site.data['localized_posts'] = (post_groups.keys.sort_by { |uuid| post_groups[uuid] }).reverse

            # Generate the index pages for each language
            languages.each do |lang|
                site.pages << LanguagePage.new(site, lang)
            end

            # Convert UUIDs to URLs in all posts
            site.posts.docs.each do |post|
                post.content = Localization.convert_uuid_to_url(site, post.content, post['lang'])
            end
        end
    end

    class CategoryGenerator < Jekyll::Generator
        safe true

        def generate(site)
            # call the add_category_collection method for each language
            site.config['languages'].each do |lang|
                add_category_collection(site, lang)
            end

            # Generate the category pages for each language
            site.config['languages'].each do |lang|
                # Find all the categories of all the posts, group them per post language
                all_category_names = site.posts.docs.select { |p| p['lang'] == lang }.map { |p| p['categories'] }.flatten.to_set

                site.data['categories'] ||= {}
                site.data['categories'][lang] ||= []

                site.collections["categories_#{lang}"].docs.each do |category|
                    all_category_names.delete(category.data['title'])
                    category_page = LocalizedCategoryPage.new(site, {'document' => category})
                    site.pages << category_page
                    site.data['categories'][lang] << category_page
                end

                all_category_names.each do |category_name|
                    category_page = LocalizedCategoryPage.new(site, {'lang' => lang, 'category' => category_name, 'uuid' => SecureRandom.uuid})
                    site.pages << category_page
                    site.data['categories'][lang] << category_page
                end
            end
        end

        def add_category_collection(site, lang)
            collection_name = "categories_#{lang}"
            site.collections[collection_name] ||= Jekyll::Collection.new(site, collection_name)

            categories_dir = File.join(site.source, "_categories", lang)
            Dir.glob(File.join(categories_dir, "*.md")).each do |file|
                doc = Jekyll::Document.new(file, site: site, collection: site.collections[collection_name])
                doc.read # need to read the file before accessing data
                doc.data['lang'] = lang
                site.collections[collection_name].docs << doc
            end
        end
    end

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

    class LocalizedCategoryPage < Jekyll::Page
        def initialize(site, params)
            # If params['document'] is not nil, initialize from document
            if params['document']
                initialize_from_document(site, params['document'])
            else
                initialize_from_dictionary(site, params)
            end
        end

        def initialize_from_document(site, document)
            lang = document.data['lang']
            category = document.data['title']
            uuid = document.data['uuid']
            content = render_document(site, document)

            initialize_from_values(site, lang, category, uuid, content)

            @data.merge!(document.data)
        end

        def initialize_from_dictionary(site, params)
            initialize_from_values(site, params['lang'], params['category'], params['uuid'], params['content'])

            @data['title'] = params['category']
        end

        def initialize_from_values(site, lang, category, uuid, content)
            category_slug = category.downcase.gsub(' ', '-')

            # For any entry in site.collections, find any document that has the same 'uuid' as the category_doc
            translations = site.collections
                .select { |k, v| k.start_with?('categories_') }
                .map { |k, v| v.docs }
                .flatten
                .select { |p| p['uuid'] == uuid }
                .map { |p| p['title'] }
                .to_set

            # Make sure the current category is included in the translations set, because
            # it may not come from a category document.
            translations.add(category)

            localized_posts = site.posts.docs
                .select { |p| p['categories'].any? { |post_category| translations.include?(post_category) } }
                .sort_by { |p| p.date }
                .reverse
                .map { |p| p['uuid'] }
                .uniq

            @site = site             # the current site instance.
            @base = site.source      # path to the source directory.
            @dir  = "#{lang}/#{category_slug}" # the directory the page will reside in.

            # All pages have the same filename, so define attributes straight away.
            @basename = 'index'      # filename without the extension.
            @ext      = '.html'      # the extension.
            @name     = 'index.html' # basically @basename + @ext.

            @data = {
                'layout' => 'archive',
                'lang' => lang,
                'category' => category,
                'category_slug' => category_slug,
                'uuid' => uuid,
                'localized_posts' => localized_posts,
                'collection_content' => content,
            }
        end

        # Placeholders that are used in constructing page URL.
        def url_placeholders
            {
                :path       => @dir,
                :lang       => @data['lang'],
                :category   => @data['category_slug'],
                :basename   => basename,
                :output_ext => output_ext,
            }
        end

        def render_document(site, document)
            # Render Liquid tags
            liquid_template = Liquid::Template.parse(document.content)
            rendered_content = liquid_template.render!(site.site_payload, { registers: { site: site, page: document } })

            # Convert UUID links to URLs
            rendered_content = Localization.convert_uuid_to_url(site, rendered_content, document.data['lang'])

            # Convert Markdown to HTML
            markdown_converter = site.find_converter_instance(Jekyll::Converters::Markdown)
            markdown_converter.convert(rendered_content)
        end
    end

    def self.convert_uuid_to_url(site, content, post_lang)
        uuid_regex = /\b[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}\b/
        content.gsub(/\[([^\]]+)\]\((#{uuid_regex})(\/\w{2})?\)/) do |match|
            text = $1
            uuid = $2
            lang = $3&.gsub('/', '')

            prefered_lang = lang || post_lang
            post = find_prefered_translation(site, uuid, prefered_lang)

            if post
                "[#{text}](#{post.url})"
            else
                match
            end
        end.gsub(/\[(#{uuid_regex})\]/) do |match|
            uuid = $1
            post = find_prefered_translation(site, uuid, post_lang)

            if post
                "[#{post.data['title']}](#{post.url})"
            else
                match
            end
        end
    end

    def self.find_prefered_translation(site, uuid, lang)
        post = site.posts.docs.find { |p| p['uuid'] == uuid && p['lang'] == lang }
        return post if post

        languages = site.config['languages']
        for language in languages
            post = site.posts.docs.find { |p| p['uuid'] == uuid && p['lang'] == language }
            return post if post
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

        def group_by_uuid(posts)
            # Sort by date and return the UUID
            posts.sort_by { |p| p.date }.reverse.map { |p| p['uuid'] }.uniq
        end

        def localize(string, lang)
            return string if lang.nil?
            translations = @context.registers[:site].data['localization'][string]
            raise "No translations found for string '#{string}'" if translations.nil?
            translations[lang] || string
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

        def translation_url(uuid, lang)
            post = find_prefered_translation(uuid, lang)
            return post.url if post
        end

        def get_category_by_name(category_name, lang)
            site = @context.registers[:site]
            site.data['categories'][lang].find { |c| c.data['title'] == category_name }
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

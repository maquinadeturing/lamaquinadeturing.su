require 'securerandom'

module Localization
    class LanguageGenerator < Jekyll::Generator
        safe true

        def generate(site)
            # Define an empty map
            post_groups = {}
            languages = {}

            site.posts.docs.each do |post|
                languages[post['lang']] = true

                # Group posts by their 'uuid' property. If the 'uuid' property is not defined, generate a random one
                uuid = post['uuid'] || SecureRandom.uuid

                # Assign the 'uuid' property to the post
                post.data['uuid'] = uuid

                # Add the post to the set
                post_groups[uuid] = post.date
            end

            # Assign the languages to site.data['languages']
            site.data['languages'] = languages.keys

            # Assign the keys of the post_groups map to site.data['localized_posts'] as an array sorted by date
            site.data['localized_posts'] = (post_groups.keys.sort_by { |uuid| post_groups[uuid] }).reverse

            # Generate the index pages for each language
            languages.keys.each do |lang|
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
        def translations(post)
            @context.registers[:site].posts.docs.select { |p| p['uuid'] == post['uuid'] && p['lang'] != post['lang'] }
        end

        def localize(string, lang)
            return string if lang.nil?
            @context.registers[:site].data['localization'][string][lang]
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
end

Liquid::Template.register_filter(Jekyll::LocalizationFilter)
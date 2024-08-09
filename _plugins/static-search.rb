module StaticSearch
    class StaticSearchIndexGenerator < Jekyll::Generator
        safe true
        priority :low

        def generate(site)
            # For each post, render the post and extract a list with all the unique words.
            # Create a JSON with one entry per each word, containing the list of posts that contain that word.
            index = {}

            post_table = []
            stopwords = {}

            site.posts.docs.each do |post|
                lang = post.data['lang']
                if lang.nil? then
                    Jekyll.logger.warn "Search index:", "Post #{post.url} has no language"
                    next
                end

                if stopwords[lang].nil? then
                    stopwords[lang] = Set.new
                    stopwords_path = File.join(site.source, "_plugin_data", "stopwords_#{lang}.json")
                    if File.exist?(stopwords_path) then
                        stopwords[lang] = JSON.parse(File.read(stopwords_path)).to_set
                    end
                end

                rendered_content = site.liquid_renderer.file(post.path).parse(post.content).render(site.site_payload)
                html_content = site.find_converter_instance(Jekyll::Converters::Markdown).convert(rendered_content)

                text_content = html_content.gsub(/<\/?[^>]*>/, ' ')

                valid_chars = 'a-zA-Z0-9áéíóúàèìòùäëïöüâêîôûçñÁÉÍÓÚÀÈÌÒÙÄËÏÖÜÂÊÎÔÛÇÑ·'
                text_content = text_content.gsub(/[^#{valid_chars}]/, ' ')

                words = text_content.downcase.split(' ')
                    .filter { |word| word.length > 1 }
                    .filter { |word| !word.match?(/^\d+$/) }
                    .filter { |word| !stopwords[lang].include?(word) }
                    .sort
                    .uniq

                if words.length == 0 then
                    next
                end

                post_index = post_table.length
                post_table << {
                    "url" => post.url,
                    "title" => post.data['title'],
                    "date" => post.data['date'],
                    "lang" => lang,
                    "uuid" => post.data['uuid']
                }

                words.each do |word, count|
                    index[lang] ||= {}
                    if index[lang][word].nil? then
                        index[lang][word] = post_index
                    elsif index[lang][word].is_a?(Array) then
                        index[lang][word] << post_index
                    else
                        index[lang][word] = [index[lang][word], post_index]
                    end
                end
            end

            index_path = '/search-index.json'

            site.pages << Jekyll::PageWithoutAFile.new(site, __dir__, "", index_path).tap do |file|
                file.content = JSON.generate({ "index" => index, "posts" => post_table })
                file.data.merge!(
                    "layout"     => nil,
                    "sitemap"    => false,
                )
                Jekyll.logger.info "Search index:", "Generated #{index_path} with #{file.content.length / 1024} KB"
                file.output
            end
        end
    end
end

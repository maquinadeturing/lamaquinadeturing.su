# require 'uglifier'

module Jekyll
    class Assets < Generator
        safe true

        def generate(site)
            assets_config_entries = site.config['assets'] || []

            already_processed = Set.new

            for assets_config in assets_config_entries
                if assets_config['source'] == nil || assets_config['load'] == nil then
                    Jekyll.logger.error 'Assets:', 'source and load must be defined'
                    next
                end

                source_file_list = if !assets_config['source']['files'].nil? then
                    assets_config['source']['files'].map { |file| File.join(site.source, file) }
                elsif !assets_config['source']['directory'].nil? then
                    Dir.glob(File.join(site.source, assets_config['source']['directory'], '*'))
                        .reject { |file| already_processed.include?(file) }
                end

                if source_file_list.nil? then
                    Jekyll.logger.error 'Assets:', 'source must be defined as files or directory'
                    next
                end

                already_processed.merge(source_file_list)

                asset_type = assets_config['type'].downcase

                combined = source_file_list.map { |file| "/* #{File.basename(file)} */\n#{File.read(file)}" }.join("\n")

                site.static_files.reject! { |file| source_file_list.include?(file.path) }

                if assets_config['load'] == 'inlined' then
                    Jekyll.logger.info 'Assets:', "Inlined #{source_file_list.size} #{asset_type.upcase} files with #{combined.size / 1024} KB"
                    site.data["inlined_#{asset_type}"] = combined
                elsif ['linked', 'deferred'].include?(assets_config['load']) then
                    if assets_config['output'].nil?
                        Jekyll.logger.error 'Assets:', "output must be defined if load is not inlined"
                        next
                    end

                    site.pages << Jekyll::PageWithoutAFile.new(site, __dir__, "", assets_config['output']).tap do |file|
                        file.content = combined
                        file.data.merge!(
                            "layout"     => nil,
                            "sitemap"    => false,
                        )
                        Jekyll.logger.info 'Assets:', "Combined #{source_file_list.size} #{asset_type.upcase} files with #{combined.size / 1024} KB"

                        file.output
                    end

                    site.data["#{assets_config['load']}_#{asset_type}"] ||= []
                    site.data["#{assets_config['load']}_#{asset_type}"] << assets_config['output']
                else
                    Jekyll.logger.error 'Assets:', "Unknown load type #{assets_config['load']}"
                    next
                end
            end
        end
    end

    module InlineAssets
        class InlineAssetsTag < Liquid::Tag
            def initialize(tag_name, text, tokens)
                super
            end

            def render(context)
                site = context.registers[:site]

                asset_types = ['css', 'js']

                asset_types.map do |asset_type|
                    content = []
                    if site.data["linked_#{asset_type}"] then
                        content << render_linked(site.data["linked_#{asset_type}"], asset_type)
                    end
                    if site.data["inlined_#{asset_type}"] then
                        content << render_inline(site.data["inlined_#{asset_type}"], asset_type)
                    end
                    if site.data["deferred_#{asset_type}"] then
                        content << render_deferred(site.data["deferred_#{asset_type}"], asset_type)
                    end
                    content.join("\n")
                end.join("\n")
            end

            def render_linked(asset_paths, asset_type)
                if asset_type == 'css' then
                    asset_paths.map { |asset_path| "<link rel=\"stylesheet\" href=\"#{asset_path}\" type=\"text/css\">" }.join("\n")
                elsif asset_type == 'js' then
                    asset_paths.map { |asset_path| "<script src=\"#{asset_path}\"></script>" }.join("\n")
                else
                    Jekyll.logger.error 'InlineAssets:', "Unknown asset type #{asset_type}"
                    ''
                end
            end

            def render_inline(content, asset_type)
                if asset_type == 'css' then
                    "<style>#{content}</style>"
                elsif asset_type == 'js' then
                    "<script>#{content}</script>"
                else
                    Jekyll.logger.error 'InlineAssets:', "Unknown asset type #{asset_type}"
                    ''
                end
            end

            def render_deferred(asset_paths, asset_type)
                if asset_type == 'css' then
                    sources = asset_paths.map { |asset_path| "'#{asset_path}'" }.join(', ')
                    "<script>
function loadStyleSheets(...sources) {
    for (const src of sources) {
        if (document.createStyleSheet) document.createStyleSheet(src);
        else {
            var stylesheet = document.createElement('link');
            stylesheet.href = src;
            stylesheet.rel = 'stylesheet';
            stylesheet.type = 'text/css';
            document.getElementsByTagName('head')[0].appendChild(stylesheet);
        }
    }
}
loadStyleSheets(#{sources});
</script>"
                elsif asset_type == 'js' then
                    asset_paths.map { |asset_path| "<script defer src=\"#{asset_path}\"></script>" }.join("\n")
                else
                    Jekyll.logger.error 'InlineAssets:', "Unknown asset type #{asset_type}"
                    ''
                end
            end
        end
    end
end

Liquid::Template.register_tag('inline_assets', Jekyll::InlineAssets::InlineAssetsTag)

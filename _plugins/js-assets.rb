# require 'uglifier'

module Jekyll
    class JSAssets < Generator
        safe true

        def generate(site)
            source_assets = File.join(site.source, 'assets/js/*.js')
            combined_path = '/assets/js/combined.js'
            js_files = Dir.glob(source_assets)

            combined_js = js_files.map { |file| "/* #{File.basename(file)} */\n#{File.read(file)}" }.join("\n")
            # combined_js = Uglifier.new(:harmony => true).compile(combined_js)

            site.pages << Jekyll::PageWithoutAFile.new(site, __dir__, "", combined_path).tap do |file|
                file.content = combined_js
                file.data.merge!(
                    "layout"     => nil,
                    "sitemap"    => false,
                )
                Jekyll.logger.info 'JSAssets:', "Generated #{combined_path} from #{js_files.size} files with #{combined_js.size / 1024} KB"

                file.output
            end

            site.static_files.reject! { |file| js_files.include?(file.path) }
        end
    end
end
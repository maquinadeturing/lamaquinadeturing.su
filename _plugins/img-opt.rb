require 'mini_magick'

module Jekyll
    module ImageProcessor
        class ImageProcessorGenerator < Generator
            safe true
            priority :highest

            def generate(site)
                if site.config['images'].nil? then
                    return
                end

                site.config['images'] ||= { "type": "jpeg", "quality": 85 }

                image_files = Dir.glob(File.join(site.config['images']['source'], '*'))
                    .map { |file| File.join(site.source, file) }
                    .reject { |file| site.config['images']['sizes'].any? { |size| File.basename(file, '.*').end_with?("opt#{size}") } }

                image_files.each do |image_file|
                    image = MiniMagick::Image.open(image_file)

                    site.config['images']['sizes'].each do |image_size|
                        image_base_dir = File.dirname(image_file)
                        image_base_name = File.basename(image_file, '.*')
                        image_ext = if site.config['images']['format']['type'] == 'jpeg' then
                            'jpg'
                        else
                            Jekyll.logger.error "ImageProcessor", "Unsupported image format: #{site.config['images']['format']['type']}"
                            next
                        end
                        output_file = File.join(image_base_dir, "#{image_base_name}_opt#{image_size}.#{image_ext}")

                        next if File.exist?(output_file) && File.mtime(output_file) > File.mtime(image_file)

                        image.resize image_size

                        image.format site.config['images']['format']['type']
                        image.quality site.config['images']['format']['quality']
                        image.write output_file
                    end
                end
            end
        end
    end

    module ImageOptFilter
        def image_path(image_file_name)
            srcset_renderer = ImageSrcsetRenderer.new(@context.registers[:site], image_file_name)
            srcset_renderer.path
        end

        def srcset(image_file_name, *sizes)
            srcset_renderer = ImageSrcsetRenderer.new(@context.registers[:site], image_file_name)
            srcset_renderer.render_srcset(sizes)
        end
    end

    class ImageSrcsetRenderer
        def initialize(site, image_file_name)
            image_config = site.config['images']
            if image_config.nil? then
                Jekyll.logger.error "ImageProcessor", "No image configuration found"
                return
            end

            image_file = File.join(site.source, File.join(image_config['source'], image_file_name))
            if !File.exist?(image_file) then
                Jekyll.logger.error "ImageProcessor", "Image file not found: #{image_file_name}"
                return
            end

            image_base_dir = File.dirname(image_file)
            @image_base_path = File.join('/', Pathname.new(image_base_dir).relative_path_from(Pathname.new(site.source)).to_s)
            @image_base_name = File.basename(image_file, '.*')
            @image_ext = if image_config['format']['type'] == 'jpeg' then
                'jpg'
            else
                Jekyll.logger.error "ImageProcessor", "Unsupported image format: #{image_config['format']['type']}"
                return
            end

            @image_original_path = File.join(@image_base_path, image_file_name)
        end

        def path_from_size(size)
            File.join(@image_base_path, "#{@image_base_name}_opt#{size}.#{@image_ext}")
        end

        def path
            @image_original_path
        end

        def render_src
            "src=\"#{@image_original_path}\""
        end

        def render_srcset(sizes)
            srcset_values = sizes.map do |size|
                "#{path_from_size(size)} #{size}w"
            end.join(', ')

            "src=\"#{@image_original_path}\" srcset=\"#{srcset_values}\""
        end
    end
end

Liquid::Template.register_filter(Jekyll::ImageOptFilter)

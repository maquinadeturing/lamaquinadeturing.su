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

                site.config['images'] ||= {}
                site.config['images']['source'] ||= 'images'
                site.config['images']['format'] ||= {}
                site.config['images']['format']['type'] ||= 'jpeg'
                site.config['images']['format']['quality'] ||= 85
                image_sizes = (site.config['images']['sizes'] || []).map do |size|
                    if size.is_a?(String) || size.is_a?(Integer) then
                        {'size' => size, 'quality' => site.config['images']['format']['quality']}
                    else
                        size
                    end
                end

                image_files = Dir.glob(File.join(site.config['images']['source'], '*'))
                    .map { |file| File.join(site.source, file) }
                    .reject { |file| File.basename(file, '.*').end_with?("_opt") }
                    .reject { |file| image_sizes.map { |size_obj| size_obj['size'] }.any? do |size|
                        File.basename(file, '.*').end_with?("_opt#{size}")
                    end }

                image_files.each do |image_file|
                    image_base_dir = File.dirname(image_file)
                    image_base_name = File.basename(image_file, '.*')
                    image_ext = if site.config['images']['format']['type'] == 'jpeg' then
                        'jpg'
                    else
                        Jekyll.logger.error "ImageProcessor", "Unsupported image format: #{site.config['images']['format']['type']}"
                        next
                    end

                    MiniMagick::Image.open(image_file).tap do |image|
                        output_file = File.join(image_base_dir, "#{image_base_name}_opt.#{image_ext}")

                        next if (File.exist?(output_file) && (
                            File.mtime(output_file) > File.mtime(image_file) &&
                            File.mtime(output_file) > File.mtime(File.join(site.source, '_config.yml'))
                            ))

                        image.format site.config['images']['format']['type']
                        image.quality site.config['images']['format']['quality']
                        image.strip # Remove any metadata
                        image.write output_file
                    end

                    image_sizes.each do |image_size_obj|
                        image_size = image_size_obj['size']
                        image = MiniMagick::Image.open(image_file)

                        output_file = File.join(image_base_dir, "#{image_base_name}_opt#{image_size}.#{image_ext}")

                        next if (File.exist?(output_file) && (
                            File.mtime(output_file) > File.mtime(image_file) &&
                            File.mtime(output_file) > File.mtime(File.join(site.source, '_config.yml'))
                            ))

                        image.resize image_size

                        image.format site.config['images']['format']['type']
                        image.quality image_size_obj['quality']
                        image.strip # Remove any metadata
                        image.write output_file
                    end
                end
            end
        end
    end

    module ImageOptFilter
        def image_path(image_file_name, size)
            srcset_renderer = ImageSrcsetRenderer.new(@context.registers[:site], image_file_name)
            if size.nil? then
                srcset_renderer.path
            else
                srcset_renderer.path_from_size(size)
            end
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

            @image_original_path = File.join(@image_base_path, "#{@image_base_name}_opt.#{@image_ext}")
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

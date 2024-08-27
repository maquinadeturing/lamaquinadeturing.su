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

                image_files.each do |image_file|
                    image_relative_dir = Pathname.new(image_file).dirname.relative_path_from(Pathname.new(site.source)).to_s
                    image_ext = if site.config['images']['format']['type'] == 'jpeg' then
                        'jpg'
                    else
                        Jekyll.logger.error "ImageProcessor", "Unsupported image format: #{site.config['images']['format']['type']}"
                        next
                    end

                    site.static_files.reject! { |file| file.path == image_file }

                    site.static_files << ImageStaticFile.new(
                        site,
                        site.source,
                        image_relative_dir,
                        File.basename(image_file),
                        site.config['images']['format']['type'],
                        site.config['images']['format']['quality'],
                        image_ext
                    )
                    site.static_files += image_sizes.map do |image_size_obj|
                        ImageStaticFile.new(
                            site,
                            site.source,
                            image_relative_dir,
                            File.basename(image_file),
                            site.config['images']['format']['type'],
                            image_size_obj['quality'],
                            image_ext,
                            image_size_obj['size']
                        )
                    end
                end
            end
        end

        # A static file that references an existing source image file, but
        # its methods are overridden to generate an optimized version of the image
        # with a different format, quality and optionally size, and a customized
        # destination file name and URL.
        class ImageStaticFile < StaticFile
            def initialize(site, base, dir, name, format, quality, ext, size = nil)
                super(site, base, dir, name)
                @format = format
                @quality = quality
                @ext = ext
                @size = size
            end

            def destination(dest)
                output_file_name = "#{File.basename(@name, '.*')}_opt#{@size}.#{@ext}"
                File.join(dest, @dir, output_file_name)
            end

            def write(dest)
                dest_path = destination(dest)
                output_file_name = File.basename(dest_path)

                if File.exist?(dest_path) then
                    older_than_source = File.mtime(dest_path) < File.mtime(File.join(@base, @dir, @name))
                    older_than_config = File.mtime(dest_path) < File.mtime(File.join(@site.source, '_config.yml'))
                    return false if File.exist?(dest_path) && !older_than_source && !older_than_config
                end

                FileUtils.mkdir_p(File.dirname(dest_path))
                image = MiniMagick::Image.open(File.join(@base, @dir, @name))
                image.resize @size if @size
                image.format @format
                image.quality @quality
                image.strip # Remove EXIF data
                image.write(dest_path)

                file_size_variation = -(1 - File.size(dest_path).to_f / File.size(File.join(@base, @dir, @name)).to_f) * 100
                Jekyll.logger.info "ImageProcessor", "Processing #{@name} to #{output_file_name} (#{'%+d' % file_size_variation}%)"
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

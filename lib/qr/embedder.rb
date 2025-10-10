# frozen_string_literal: true

require 'mini_magick'

module QR
  # Embeds QR code into image
  class Embedder
    MIN_IMAGE_SIZE = 300
    QR_SIZE_RATIO = 0.25
    EDGE_PADDING = 20
    BRIGHTNESS_SHIFT = 0.28

    def embed(image_path, qr_code, data_type = nil)
      raise ArgumentError, "Image file does not exist: #{image_path}" unless File.exist?(image_path)
      raise ArgumentError, 'QR code cannot be nil' if qr_code.nil?

      validate_image_size!(image_path)
      embed_qr_steganography(image_path, qr_code.modules, data_type)
    end

    private

    def validate_image_size!(image_path)
      image = MiniMagick::Image.open(image_path)
      min_dimension = [image.width, image.height].min

      if min_dimension < MIN_IMAGE_SIZE
        raise ArgumentError, "Image is too small (#{min_dimension}px). Minimum: #{MIN_IMAGE_SIZE}px"
      end
    end

    def embed_qr_steganography(image_path, qr_matrix, data_type = nil)
      base_image = MiniMagick::Image.open(image_path)
      qr_pixel_size = calculate_qr_size(base_image, qr_matrix)
      qr_offset_x, qr_offset_y = calculate_position(base_image, qr_pixel_size, qr_matrix.size)

      # Adjust brightness based on data type
      brightness_shift = get_brightness_shift(data_type)

      overlay_path = create_overlay(base_image, qr_matrix, qr_pixel_size, qr_offset_x, qr_offset_y, brightness_shift)
      result_path = apply_overlay(base_image, overlay_path)

      File.delete(overlay_path) if File.exist?(overlay_path)
      result_path
    end

    def calculate_qr_size(image, qr_matrix)
      max_qr_dimension = [image.width, image.height].min * QR_SIZE_RATIO
      (max_qr_dimension / qr_matrix.size).to_i
    end

    def calculate_position(image, qr_pixel_size, qr_modules)
      total_qr_size = qr_pixel_size * qr_modules
      offset_x = image.width - total_qr_size - EDGE_PADDING
      offset_y = image.height - total_qr_size - EDGE_PADDING
      [offset_x, offset_y]
    end

    def get_brightness_shift(data_type)
      case data_type
      when 'vcard'
        0.35  # Higher contrast for vCard (harder to scan)
      when 'url', 'text'
        0.28  # Normal contrast for URL/text
      else
        BRIGHTNESS_SHIFT  # Default
      end
    end

    def create_overlay(base_image, qr_matrix, qr_pixel_size, offset_x, offset_y, brightness_shift = BRIGHTNESS_SHIFT)
      overlay_path = File.join(Dir.tmpdir, "overlay_#{Time.now.to_i}_#{rand(1000)}.png")

      MiniMagick::Tool::Convert.new do |convert|
        convert.size "#{base_image.width}x#{base_image.height}"
        convert << 'xc:transparent'

        qr_matrix.each_with_index do |row, row_idx|
          row.each_with_index do |is_dark, col_idx|
            x = offset_x + (col_idx * qr_pixel_size)
            y = offset_y + (row_idx * qr_pixel_size)

            bg_color = sample_background_color(base_image, x, y, qr_pixel_size)
            module_color = calculate_color(bg_color, is_dark, brightness_shift)

            convert.fill module_color
            convert.draw "rectangle #{x},#{y} #{x + qr_pixel_size},#{y + qr_pixel_size}"
          end
        end

        convert << overlay_path
      end

      overlay_path
    end

    def sample_background_color(image, x, y, size)
      sample_x = [0, [x + size / 2, image.width - 1].min].max
      sample_y = [0, [y + size / 2, image.height - 1].min].max
      
      pixel_data = image.run_command(:convert, image.path,
                                     '-crop', "1x1+#{sample_x}+#{sample_y}",
                                     '-format', '%[pixel:u]', 'info:')
      
      if pixel_data =~ /srgba?\((\d+),(\d+),(\d+)/
        { r: $1.to_i, g: $2.to_i, b: $3.to_i }
      else
        { r: 128, g: 128, b: 128 }
      end
    end

    def calculate_color(bg_color, is_dark, brightness_shift = BRIGHTNESS_SHIFT)
      r, g, b = bg_color[:r], bg_color[:g], bg_color[:b]
      
      if is_dark
        factor = 1.0 - brightness_shift
        new_r = (r * factor).to_i
        new_g = (g * factor).to_i
        new_b = (b * factor).to_i
      else
        new_r = [255, (r + (255 - r) * brightness_shift).to_i].min
        new_g = [255, (g + (255 - g) * brightness_shift).to_i].min
        new_b = [255, (b + (255 - b) * brightness_shift).to_i].min
      end
      
      "rgb(#{new_r},#{new_g},#{new_b})"
    end

    def apply_overlay(base_image, overlay_path)
      result = base_image.composite(MiniMagick::Image.open(overlay_path)) do |c|
        c.compose 'Over'
        c.gravity 'center'
      end

      output_path = File.join(Dir.tmpdir, "result_#{Time.now.to_i}_#{rand(1000)}.png")
      result.write(output_path)
      output_path
    end
  end
end
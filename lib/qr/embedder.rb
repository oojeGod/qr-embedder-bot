# frozen_string_literal: true

require 'mini_magick'

module QR
  # Embeds QR code into image
  class Embedder
    MIN_IMAGE_SIZE = 300
    QR_SIZE_RATIO = 0.25
    EDGE_PADDING = 20
    QR_OPACITY = 0.5

    def initialize(image_path:, qr_code:)
      @image_path = image_path
      @qr_code = qr_code
    end

    def embed
      raise ArgumentError, "Image file does not exist: #{image_path}" unless File.exist?(image_path)
      raise ArgumentError, 'QR code cannot be nil' if qr_code.nil?

      validate_image_size!
      embed_qr_with_overlay
    end

    private

    attr_reader :image_path, :qr_code

    def validate_image_size!
      image = MiniMagick::Image.open(image_path)
      min_dimension = [image.width, image.height].min

      if min_dimension < MIN_IMAGE_SIZE
        raise ArgumentError, "Image is too small (#{min_dimension}px). Minimum: #{MIN_IMAGE_SIZE}px"
      end
    end

    def embed_qr_with_overlay
      base_image = MiniMagick::Image.open(image_path)
      qr_matrix = qr_code.modules
      qr_pixel_size = calculate_qr_size(base_image, qr_matrix)
      qr_offset_x, qr_offset_y = calculate_position(base_image, qr_pixel_size, qr_matrix.size)

      overlay_path = create_overlay(base_image, qr_matrix, qr_pixel_size, qr_offset_x, qr_offset_y)
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

    def create_overlay(base_image, qr_matrix, qr_pixel_size, offset_x, offset_y)
      overlay_path = File.join(Dir.tmpdir, "overlay_#{Time.now.to_i}_#{rand(1000)}.png")

      MiniMagick::Tool::Convert.new do |convert|
        convert.size "#{base_image.width}x#{base_image.height}"
        convert << 'xc:transparent'

        qr_matrix.each_with_index do |row, row_idx|
          row.each_with_index do |is_dark, col_idx|
            x = offset_x + (col_idx * qr_pixel_size)
            y = offset_y + (row_idx * qr_pixel_size)

            color = is_dark ? 'black' : 'white'
            convert.fill color
            convert.draw "rectangle #{x},#{y} #{x + qr_pixel_size},#{y + qr_pixel_size}"
          end
        end

        convert << overlay_path
      end

      overlay_path
    end

    def apply_overlay(base_image, overlay_path)
      result_path = File.join(Dir.tmpdir, "result_#{Time.now.to_i}_#{rand(1000)}.png")
      
      overlay = MiniMagick::Image.open(overlay_path)
      overlay.combine_options do |c|
        c.alpha 'set'
        c.channel 'A'
        c.evaluate 'multiply', QR_OPACITY
      end
      
      base_image.composite(overlay) do |c|
        c.compose 'Over'
      end.write(result_path)

      result_path
    end
  end
end
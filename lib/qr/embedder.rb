# frozen_string_literal: true

require 'mini_magick'

module QR
  # Embeds QR code into image using steganography technique
  # QR is invisible to the naked eye but readable by camera with proper lighting/contrast
  class Embedder
    # Minimum image dimension to ensure QR readability
    MIN_IMAGE_SIZE = 300

    # QR will occupy max 40% of image dimension
    QR_SIZE_RATIO = 0.4

    # Opacity for dark modules (darker pixels)
    DARK_MODULE_OPACITY = 0.12

    # Opacity for light modules (lighter pixels)
    LIGHT_MODULE_OPACITY = 0.08

    # Embeds QR code into the provided image using pixel-level steganography
    #
    # @param image_path [String] path to the source image
    # @param qr_code [RQRCode::QRCode] QR code object to embed
    # @return [String] path to the modified image
    # @raise [ArgumentError] if image doesn't exist, is too small, or qr_code is nil
    def embed(image_path, qr_code)
      validate_inputs!(image_path, qr_code)

      qr_matrix = qr_code.modules
      result_path = embed_qr_steganography(image_path, qr_matrix)

      result_path
    end

    private

    def validate_inputs!(image_path, qr_code)
      raise ArgumentError, "Image file does not exist: #{image_path}" unless File.exist?(image_path)
      raise ArgumentError, 'QR code cannot be nil' if qr_code.nil?

      validate_image_size!(image_path)
    end

    def validate_image_size!(image_path)
      image = MiniMagick::Image.open(image_path)
      min_dimension = [image.width, image.height].min

      if min_dimension < MIN_IMAGE_SIZE
        raise ArgumentError, "Image is too small (#{min_dimension}px). Minimum: #{MIN_IMAGE_SIZE}px"
      end
    end

    # Embeds QR matrix into image by adjusting pixel brightness
    #
    # @param image_path [String] path to source image
    # @param qr_matrix [Array<Array<Boolean>>] QR code matrix
    # @return [String] path to result image
    def embed_qr_steganography(image_path, qr_matrix)
      base_image = MiniMagick::Image.open(image_path)

      # Calculate QR size and position (center, max 40% of image)
      qr_pixel_size = calculate_qr_size(base_image, qr_matrix)
      qr_offset_x, qr_offset_y = calculate_center_position(base_image, qr_pixel_size, qr_matrix.size)

      # Create brightness adjustment overlay (both dark and light modules)
      overlay_path = create_steganography_overlay(qr_matrix, qr_pixel_size, qr_offset_x, qr_offset_y,
                                                  base_image.width, base_image.height)

      # Apply overlay to base image
      result_path = apply_steganography_overlay(base_image, overlay_path)

      File.delete(overlay_path) if File.exist?(overlay_path)

      result_path
    end

    def calculate_qr_size(image, qr_matrix)
      max_qr_dimension = [image.width, image.height].min * QR_SIZE_RATIO
      (max_qr_dimension / qr_matrix.size).to_i
    end

    def calculate_center_position(image, qr_pixel_size, qr_modules)
      total_qr_size = qr_pixel_size * qr_modules
      offset_x = (image.width - total_qr_size) / 2
      offset_y = (image.height - total_qr_size) / 2
      [offset_x, offset_y]
    end

    def create_steganography_overlay(qr_matrix, qr_pixel_size, offset_x, offset_y, image_width, image_height)
      overlay_path = File.join(Dir.tmpdir, "overlay_#{Time.now.to_i}_#{rand(1000)}.png")

      MiniMagick::Tool::Convert.new do |convert|
        convert << 'xc:gray50'
        convert.size "#{image_width}x#{image_height}"

        qr_matrix.each_with_index do |row, row_idx|
          row.each_with_index do |is_dark, col_idx|
            x = offset_x + (col_idx * qr_pixel_size)
            y = offset_y + (row_idx * qr_pixel_size)

            if is_dark
              convert.fill "rgba(0,0,0,#{DARK_MODULE_OPACITY})"
            else
              convert.fill "rgba(255,255,255,#{LIGHT_MODULE_OPACITY})"
            end

            convert.draw "rectangle #{x},#{y} #{x + qr_pixel_size},#{y + qr_pixel_size}"
          end
        end

        convert << overlay_path
      end

      overlay_path
    end

    def apply_steganography_overlay(base_image, overlay_path)
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
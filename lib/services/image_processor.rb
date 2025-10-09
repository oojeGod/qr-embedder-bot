# frozen_string_literal: true

module Services
  # Orchestrates QR code generation and embedding into images
  # Main entry point for image processing workflow
  class ImageProcessor
    def initialize
      @generator = QR::Generator.new
      @embedder = QR::Embedder.new
    end

    # Processes image by generating QR code and embedding it
    #
    # @param image_path [String] path to the source image
    # @param qr_data [String] data to encode in QR (URL, text, vCard)
    # @return [String] path to the processed image with embedded QR code
    # @raise [ArgumentError] if image doesn't exist or qr_data is invalid
    def process(image_path, qr_data)
      qr_code = @generator.generate(qr_data)
      result_path = @embedder.embed(image_path, qr_code)

      result_path
    end
  end
end
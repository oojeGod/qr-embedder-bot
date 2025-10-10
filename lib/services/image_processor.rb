# frozen_string_literal: true

module Services
  # Orchestrates QR code generation and embedding into images
  # Main entry point for image processing workflow
  class ImageProcessor
    def initialize
      @generator = QR::Generator.new
      @embedder = QR::Embedder.new
    end

    def process(image_path, qr_data, data_type = nil)
      qr_code = @generator.generate(qr_data)
      result_path = @embedder.embed(image_path, qr_code, data_type)

      result_path
    end
  end
end
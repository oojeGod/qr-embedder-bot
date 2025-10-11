# frozen_string_literal: true

module Services
  # Orchestrates QR code generation and embedding into images
  # Main entry point for image processing workflow
  class ImageProcessor
    def initialize(image_path, qr_data)
      @image_path = image_path
      @qr_data = qr_data
    end

    def process
      qr_generator = QR::Generator.new(qr_data)
      qr_code = qr_generator.generate
      
      embedder = QR::Embedder.new(image_path, qr_code)
      result_path = embedder.embed

      result_path
    end

    private

    attr_reader :image_path, :qr_data
  end
end
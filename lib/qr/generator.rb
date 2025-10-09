# frozen_string_literal: true

require 'rqrcode'

module QR
  # Generates QR codes from text data
  class Generator
    # Generates a QR code from the provided data
    #
    # @param data [String] text, URL or vCard to encode
    # @return [RQRCode::QRCode] QR code object
    # @raise [ArgumentError] if data is empty or nil
    def generate(data)
      validate_data!(data)

      RQRCode::QRCode.new(data, level: :h)
    end

    private

    def validate_data!(data)
      raise ArgumentError, 'Data cannot be empty' if data.nil? || data.to_s.strip.empty?
    end
  end
end
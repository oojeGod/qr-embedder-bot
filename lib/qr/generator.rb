# frozen_string_literal: true

require 'rqrcode'

module QR
  # Generates QR codes from text data
  class Generator
    def initialize(data)
      @data = data
    end

    def generate
      validate_data!

      RQRCode::QRCode.new(data, level: :h)
    end

    private

    attr_reader :data

    def validate_data!
      raise ArgumentError, 'Data cannot be empty' if data.nil? || data.to_s.strip.empty?
    end
  end
end
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QR::Generator do
  describe '#generate' do
    let(:generator) { described_class.new }
    let(:data) { 'https://example.com' }

    it 'generates QR code from string data' do
      qr_code = generator.generate(data)

      expect(qr_code).to be_a(RQRCode::QRCode)
      expect(qr_code.to_s).not_to be_empty
    end

    it 'raises error for empty data' do
      expect { generator.generate('') }.to raise_error(ArgumentError, 'Data cannot be empty')
    end

    it 'raises error for nil data' do
      expect { generator.generate(nil) }.to raise_error(ArgumentError, 'Data cannot be empty')
    end
  end
end
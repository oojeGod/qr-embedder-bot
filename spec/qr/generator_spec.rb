# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QR::Generator do
  subject(:generator) { described_class.new(data: data) }
  let(:data) { 'https://example.com' }

  describe '#generate' do
    context 'with valid data' do
      subject(:qr_code) { generator.generate }

      it 'returns QRCode instance' do
        expect(qr_code).to be_a(RQRCode::QRCode)
      end

      it 'generates non-empty QR code' do
        expect(qr_code.to_s).not_to be_empty
      end
    end

    context 'with invalid data' do
      context 'when data is empty string' do
        subject(:generator) { described_class.new(data: '') }
        
        it 'raises ArgumentError' do
          expect { generator.generate }.to raise_error(ArgumentError, 'Data cannot be empty')
        end
      end

      context 'when data is nil' do
        subject(:generator) { described_class.new(data: nil) }
        
        it 'raises ArgumentError' do
          expect { generator.generate }.to raise_error(ArgumentError, 'Data cannot be empty')
        end
      end
    end
  end
end
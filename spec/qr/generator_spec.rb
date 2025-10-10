# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QR::Generator do
  subject(:generator) { described_class.new }

  describe '#generate' do
    let(:data) { 'https://example.com' }

    context 'with valid data' do
      subject(:qr_code) { generator.generate(data) }

      it 'returns QRCode instance' do
        expect(qr_code).to be_a(RQRCode::QRCode)
      end

      it 'generates non-empty QR code' do
        expect(qr_code.to_s).not_to be_empty
      end
    end

    context 'with invalid data' do
      context 'when data is empty string' do
        it 'raises ArgumentError' do
          expect { generator.generate('') }.to raise_error(ArgumentError, 'Data cannot be empty')
        end
      end

      context 'when data is nil' do
        it 'raises ArgumentError' do
          expect { generator.generate(nil) }.to raise_error(ArgumentError, 'Data cannot be empty')
        end
      end
    end
  end
end
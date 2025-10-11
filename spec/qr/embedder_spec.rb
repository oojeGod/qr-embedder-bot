# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QR::Embedder do
  let(:qr_code) { QR::Generator.new(data: 'https://example.com').generate }
  let(:test_image_path) { create_test_image }

  after do
    File.delete(test_image_path) if File.exist?(test_image_path)
  end

  describe '#embed' do
    context 'with valid inputs' do
      subject(:result_path) { described_class.new(image_path: test_image_path, qr_code: qr_code).embed }

      it 'creates new image file' do
        expect(File).to exist(result_path)
      end

      it 'returns path different from original', :aggregate_failures do
        expect(result_path).to be_a(String)
        expect(result_path).to match(/\.png$/)
        expect(result_path).not_to eq(test_image_path)
      end

      it 'preserves original image dimensions' do
        original = MiniMagick::Image.open(test_image_path)
        result = MiniMagick::Image.open(result_path)

        expect(result).to have_attributes(
          width: original.width,
          height: original.height
        )
      end
    end

    context 'with invalid inputs' do
      context 'when image does not exist' do
        it 'raises ArgumentError' do
          expect { described_class.new(image_path: '/non/existent/image.png', qr_code: qr_code).embed }
            .to raise_error(ArgumentError, /Image file does not exist/)
        end
      end

      context 'when qr_code is nil' do
        it 'raises ArgumentError' do
          expect { described_class.new(image_path: test_image_path, qr_code: nil).embed }
            .to raise_error(ArgumentError, 'QR code cannot be nil')
        end
      end

      context 'when image is too small' do
        let(:small_image_path) { create_test_image(size: 100) }

        after do
          File.delete(small_image_path) if File.exist?(small_image_path)
        end

        it 'raises ArgumentError with size details' do
          expect { described_class.new(image_path: small_image_path, qr_code: qr_code).embed }
            .to raise_error(ArgumentError, /Image is too small/)
        end
      end
    end
  end
end
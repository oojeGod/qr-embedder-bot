# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QR::Embedder do
  describe '#embed' do
    let(:embedder) { described_class.new }
    let(:generator) { QR::Generator.new }
    let(:qr_code) { generator.generate('https://example.com') }
    let(:test_image_path) { create_test_image }

    after do
      File.delete(test_image_path) if File.exist?(test_image_path)
    end

    it 'embeds QR code into image using steganography' do
      result_path = embedder.embed(test_image_path, qr_code)

      expect(File.exist?(result_path)).to be true
      expect(result_path).not_to eq(test_image_path)
    end

    it 'returns path to modified image' do
      result_path = embedder.embed(test_image_path, qr_code)

      expect(result_path).to be_a(String)
      expect(result_path).to match(/\.png$/)
    end

    it 'preserves image dimensions' do
      result_path = embedder.embed(test_image_path, qr_code)

      original = MiniMagick::Image.open(test_image_path)
      result = MiniMagick::Image.open(result_path)

      expect(result.width).to eq(original.width)
      expect(result.height).to eq(original.height)
    end

    it 'raises error if image does not exist' do
      expect do
        embedder.embed('/non/existent/image.png', qr_code)
      end.to raise_error(ArgumentError, /Image file does not exist/)
    end

    it 'raises error if qr_code is nil' do
      expect do
        embedder.embed(test_image_path, nil)
      end.to raise_error(ArgumentError, 'QR code cannot be nil')
    end

    it 'raises error if image is too small' do
      small_image_path = create_test_image(size: 100)

      expect do
        embedder.embed(small_image_path, qr_code)
      end.to raise_error(ArgumentError, /Image is too small/)
    end
  end
end
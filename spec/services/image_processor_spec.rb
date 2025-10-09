# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Services::ImageProcessor do
  describe '#process' do
    let(:processor) { described_class.new }
    let(:test_image_path) { create_test_image }
    let(:qr_data) { 'https://example.com' }

    after do
      File.delete(test_image_path) if File.exist?(test_image_path)
    end

    it 'processes image and embeds QR code' do
      result_path = processor.process(test_image_path, qr_data)

      expect(File.exist?(result_path)).to be true
      expect(result_path).to match(/\.png$/)
    end

    it 'returns path to processed image' do
      result_path = processor.process(test_image_path, qr_data)

      expect(result_path).to be_a(String)
      expect(result_path).not_to eq(test_image_path)
    end

    it 'raises error if image does not exist' do
      expect do
        processor.process('/non/existent/image.png', qr_data)
      end.to raise_error(ArgumentError, /Image file does not exist/)
    end

    it 'raises error if qr_data is empty' do
      expect do
        processor.process(test_image_path, '')
      end.to raise_error(ArgumentError, 'Data cannot be empty')
    end

    it 'raises error if qr_data is nil' do
      expect do
        processor.process(test_image_path, nil)
      end.to raise_error(ArgumentError, 'Data cannot be empty')
    end
  end
end
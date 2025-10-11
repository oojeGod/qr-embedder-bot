# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Services::ImageProcessor do
  let(:test_image_path) { create_test_image }
  let(:qr_data) { 'https://example.com' }

  after do
    File.delete(test_image_path) if File.exist?(test_image_path)
  end

  describe '#process' do
    context 'with valid inputs' do
      subject(:result_path) { described_class.new(image_path: test_image_path, qr_data: qr_data).process }

      it 'creates processed image file' do
        expect(File).to exist(result_path)
      end

      it 'returns path to new PNG file', :aggregate_failures do
        expect(result_path).to be_a(String)
        expect(result_path).to match(/\.png$/)
        expect(result_path).not_to eq(test_image_path)
      end
    end

    context 'with invalid inputs' do
      context 'when image does not exist' do
        it 'raises ArgumentError' do
          expect { described_class.new(image_path: '/non/existent/image.png', qr_data: qr_data).process }
            .to raise_error(ArgumentError, /Image file does not exist/)
        end
      end

      context 'when qr_data is empty' do
        it 'raises ArgumentError' do
          expect { described_class.new(image_path: test_image_path, qr_data: '').process }
            .to raise_error(ArgumentError, 'Data cannot be empty')
        end
      end

      context 'when qr_data is nil' do
        it 'raises ArgumentError' do
          expect { described_class.new(image_path: test_image_path, qr_data: nil).process }
            .to raise_error(ArgumentError, 'Data cannot be empty')
        end
      end
    end
  end
end
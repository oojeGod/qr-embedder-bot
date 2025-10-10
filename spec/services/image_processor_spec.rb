# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Services::ImageProcessor do
  subject(:processor) { described_class.new }

  describe '#process' do
    let(:test_image_path) { create_test_image }
    let(:qr_data) { 'https://example.com' }

    after do
      File.delete(test_image_path) if File.exist?(test_image_path)
    end

    context 'with valid inputs' do
      subject(:result_path) { processor.process(test_image_path, qr_data) }

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
          expect { processor.process('/non/existent/image.png', qr_data) }
            .to raise_error(ArgumentError, /Image file does not exist/)
        end
      end

      context 'when qr_data is empty' do
        it 'raises ArgumentError' do
          expect { processor.process(test_image_path, '') }
            .to raise_error(ArgumentError, 'Data cannot be empty')
        end
      end

      context 'when qr_data is nil' do
        it 'raises ArgumentError' do
          expect { processor.process(test_image_path, nil) }
            .to raise_error(ArgumentError, 'Data cannot be empty')
        end
      end
    end
  end
end
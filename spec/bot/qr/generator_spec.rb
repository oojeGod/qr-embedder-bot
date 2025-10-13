# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bot::Qr::Generator do
  subject(:generator) { described_class.new(bot: bot, chat_id: chat_id, qr_data: qr_data) }

  let(:bot) { double('bot', api: api) }
  let(:api) { double('api') }
  let(:chat_id) { 12_345 }
  let(:qr_data) { 'https://example.com' }
  let(:file_id) { 'photo_123' }
  let(:file_path) { '/tmp/photo.jpg' }
  let(:result_path) { '/tmp/result.png' }

  before do
    Bot::UserStateManager.store_photo(chat_id: chat_id, file_id: file_id)
    
    allow(api).to receive(:send_message)
    allow(api).to receive(:send_photo)
    allow(File).to receive(:exist?).and_return(false)
    allow(File).to receive(:delete)
  end

  after do
    Bot::UserStateManager.cleanup(chat_id: chat_id)
  end

  describe '#generate' do
    let(:photo_downloader) { instance_double(Bot::PhotoDownloader, download: file_path) }
    let(:image_processor) { instance_double(Services::ImageProcessor, process: result_path) }

    before do
      allow(Bot::PhotoDownloader).to receive(:new)
        .with(bot: bot, file_id: file_id)
        .and_return(photo_downloader)
      allow(Services::ImageProcessor).to receive(:new)
        .with(image_path: file_path, qr_data: qr_data)
        .and_return(image_processor)
      allow(Faraday::UploadIO).to receive(:new).and_return(double('upload'))
    end

    it 'sends processing message' do
      expect(api).to receive(:send_message).with(hash_including(
        chat_id: chat_id,
        text: /Processing/
      ))
      generator.generate
    end

    it 'downloads photo from Telegram' do
      expect(photo_downloader).to receive(:download).and_return(file_path)
      generator.generate
    end

    it 'processes image with QR code' do
      expect(image_processor).to receive(:process).and_return(result_path)
      generator.generate
    end

    it 'sends result photo' do
      expect(api).to receive(:send_photo).with(hash_including(
        chat_id: chat_id,
        caption: /Done/
      ))
      generator.generate
    end

    it 'cleans up user state' do
      generator.generate
      expect(Bot::UserStateManager.has_photo?(chat_id: chat_id)).to be_falsey
    end

    it 'returns result path' do
      expect(generator.generate).to eq(result_path)
    end

    context 'when files exist after processing' do
      before do
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:exist?).with(result_path).and_return(true)
      end

      it 'deletes temporary files' do
        expect(File).to receive(:delete).with(file_path)
        expect(File).to receive(:delete).with(result_path)
        generator.generate
      end
    end

    context 'when ArgumentError occurs' do
      let(:error) { ArgumentError.new('Image is too small') }

      before do
        allow(image_processor).to receive(:process).and_raise(error)
      end

      it 'sends error message' do
        expect(api).to receive(:send_message).with(hash_including(
          chat_id: chat_id,
          text: /Image too small/
        ))
        expect { generator.generate }.to raise_error(ArgumentError)
      end

      it 'cleans up user state' do
        expect { generator.generate }.to raise_error(ArgumentError)
        expect(Bot::UserStateManager.has_photo?(chat_id: chat_id)).to be_falsey
      end

      it 're-raises the error' do
        expect { generator.generate }.to raise_error(ArgumentError, /Image is too small/)
      end
    end

    context 'when empty data error occurs' do
      let(:qr_data) { '' }
      let(:error) { ArgumentError.new('Data cannot be empty') }

      before do
        allow(image_processor).to receive(:process).and_raise(error)
      end

      it 'sends formatted error message' do
        expect(api).to receive(:send_message).with(hash_including(
          chat_id: chat_id,
          text: /Data cannot be empty/
        ))
        expect { generator.generate }.to raise_error(ArgumentError)
      end
    end
  end
end


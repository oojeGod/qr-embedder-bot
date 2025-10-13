# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bot::Callbacks::Builder do
  subject(:builder) { described_class.new(bot: bot, chat_id: chat_id) }

  let(:bot) { double('bot', api: api) }
  let(:api) { double('api') }
  let(:chat_id) { 12_345 }

  describe '#send_welcome' do
    it 'sends welcome message' do
      expect(api).to receive(:send_message).with(hash_including(
        chat_id: chat_id,
        text: /Welcome to QR Embedder Bot/
      ))
      builder.send_welcome
    end
  end

  describe '#send_photo_received' do
    it 'sends photo received message with keyboard' do
      expect(api).to receive(:send_message).with(hash_including(
        chat_id: chat_id,
        text: /Photo received/,
        reply_markup: be_a(Telegram::Bot::Types::InlineKeyboardMarkup)
      ))
      builder.send_photo_received
    end
  end

  describe '#send_processing' do
    it 'sends processing message' do
      expect(api).to receive(:send_message).with(hash_including(
        chat_id: chat_id,
        text: /Processing your image/
      ))
      builder.send_processing
    end
  end

  describe '#send_result' do
    let(:result_path) { '/tmp/result.png' }

    before do
      allow(File).to receive(:read).with(result_path).and_return('fake_image')
      allow(Faraday::UploadIO).to receive(:new).and_return(double('upload'))
    end

    it 'sends photo with caption' do
      expect(api).to receive(:send_photo).with(hash_including(
        chat_id: chat_id,
        caption: /Done/
      ))
      builder.send_result(result_path: result_path)
    end

    context 'when bot is nil' do
      let(:bot) { nil }

      it 'raises error' do
        expect { builder.send_result(result_path: result_path) }
          .to raise_error(/Bot instance required/)
      end
    end
  end

  describe '#send_error' do
    context 'with image too small error' do
      let(:error) { ArgumentError.new('Image is too small (250px). Minimum: 300px') }

      it 'sends formatted error message' do
        expect(api).to receive(:send_message).with(hash_including(
          chat_id: chat_id,
          text: /Image too small/
        ))
        builder.send_error(error: error)
      end
    end

    context 'with empty data error' do
      let(:error) { ArgumentError.new('Data cannot be empty') }

      it 'sends formatted error message' do
        expect(api).to receive(:send_message).with(hash_including(
          chat_id: chat_id,
          text: /Data cannot be empty/
        ))
        builder.send_error(error: error)
      end
    end

    context 'with generic error' do
      let(:error) { StandardError.new('Something went wrong') }

      it 'sends generic error message' do
        expect(api).to receive(:send_message).with(hash_including(
          chat_id: chat_id,
          text: /Error: Something went wrong/
        ))
        builder.send_error(error: error)
      end
    end
  end

  describe '#send_ask_photo' do
    it 'asks user to send photo' do
      expect(api).to receive(:send_message).with(hash_including(
        chat_id: chat_id,
        text: /Please send a photo first/
      ))
      builder.send_ask_photo
    end
  end

  describe '#send_qr_prompt' do
    context 'with url type' do
      it 'sends URL prompt' do
        expect(api).to receive(:send_message).with(hash_including(
          chat_id: chat_id,
          text: /Send me the URL/
        ))
        builder.send_qr_prompt(qr_type: 'url')
      end
    end

    context 'with text type' do
      it 'sends text prompt' do
        expect(api).to receive(:send_message).with(hash_including(
          chat_id: chat_id,
          text: /Send me any text/
        ))
        builder.send_qr_prompt(qr_type: 'text')
      end
    end
  end

  describe '#send_message' do
    let(:text) { 'Test message' }

    context 'without reply markup' do
      it 'sends message with text only' do
        expect(api).to receive(:send_message).with(hash_including(
          chat_id: chat_id,
          text: text
        ))
        builder.send_message(text: text)
      end
    end

    context 'with reply markup' do
      let(:markup) { double('markup') }

      it 'sends message with text and reply markup' do
        expect(api).to receive(:send_message).with(hash_including(
          chat_id: chat_id,
          text: text,
          reply_markup: markup
        ))
        builder.send_message(text: text, reply_markup: markup)
      end
    end

    context 'when bot is nil' do
      let(:bot) { nil }

      it 'raises error' do
        expect { builder.send_message(text: text) }
          .to raise_error(/Bot instance required/)
      end
    end
  end
end


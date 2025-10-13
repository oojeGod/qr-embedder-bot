# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bot::Messages::Handler do
  subject(:handler) { described_class.new(bot: bot, message: message) }

  let(:bot) { double('bot', api: api) }
  let(:api) { double('api') }
  let(:chat_id) { 12_345 }
  let(:chat) { double('chat', id: chat_id) }

  after do
    Bot::UserStateManager.cleanup(chat_id: chat_id)
  end

  describe '#handle_photo' do
    let(:photo) { [double('photo', file_id: 'photo_123')] }
    let(:message) { double('message', chat: chat, photo: photo) }

    it 'sends photo received message with keyboard' do
      expect(api).to receive(:send_message).with(hash_including(
        text: /Photo received/,
        reply_markup: be_a(Telegram::Bot::Types::InlineKeyboardMarkup)
      ))
      handler.handle_photo
    end
  end

  describe '#handle_text' do
    context 'with /start command' do
      let(:message) { double('message', chat: chat, text: '/start') }

      it 'sends welcome message' do
        expect(api).to receive(:send_message).with(hash_including(
          text: /Welcome to QR Embedder Bot/
        ))
        handler.handle_text
      end
    end

    context 'with text when no photo stored' do
      let(:message) { double('message', chat: chat, text: 'some text') }

      it 'asks user to send photo first' do
        expect(api).to receive(:send_message).with(hash_including(
          text: /Please send a photo first/
        ))
        handler.handle_text
      end
    end

    context 'with text when waiting for QR data' do
      let(:message) { double('message', chat: chat, text: 'https://example.com') }
      let(:qr_generator) { instance_double(Bot::Qr::Generator) }

      before do
        Bot::UserStateManager.store_photo(chat_id: chat_id, file_id: 'photo_123')
        Bot::UserStateManager.set_qr_type(chat_id: chat_id, qr_type: 'url')
        allow(Bot::Qr::Generator).to receive(:new).and_return(qr_generator)
        allow(qr_generator).to receive(:generate)
      end

      it 'creates QR generator with text data' do
        expect(Bot::Qr::Generator).to receive(:new).with(
          bot: bot,
          chat_id: chat_id,
          qr_data: 'https://example.com'
        ).and_return(qr_generator)
        handler.handle_text
      end

      it 'calls generate on QR generator' do
        expect(qr_generator).to receive(:generate)
        handler.handle_text
      end
    end

    context 'with text containing leading/trailing spaces' do
      let(:message) { double('message', chat: chat, text: '  https://example.com  ') }
      let(:qr_generator) { instance_double(Bot::Qr::Generator) }

      before do
        Bot::UserStateManager.store_photo(chat_id: chat_id, file_id: 'photo_123')
        Bot::UserStateManager.set_qr_type(chat_id: chat_id, qr_type: 'url')
        allow(Bot::Qr::Generator).to receive(:new).and_return(qr_generator)
        allow(qr_generator).to receive(:generate)
      end

      it 'strips whitespace before processing' do
        expect(Bot::Qr::Generator).to receive(:new).with(
          bot: bot,
          chat_id: chat_id,
          qr_data: 'https://example.com'
        ).and_return(qr_generator)
        handler.handle_text
      end
    end
  end
end


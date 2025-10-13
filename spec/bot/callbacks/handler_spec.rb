# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bot::Callbacks::Handler do
  subject(:handler) { described_class.new(bot: bot, callback_query: callback_query) }

  let(:bot) { double('bot', api: api) }
  let(:api) { double('api') }
  let(:chat_id) { 12_345 }
  let(:message) { double('message', chat: double('chat', id: chat_id)) }
  let(:callback_query) { double('callback_query', data: qr_type, message: message) }

  before do
    Bot::UserStateManager.store_photo(chat_id: chat_id, file_id: 'photo_123')
  end

  after do
    Bot::UserStateManager.cleanup(chat_id: chat_id)
  end

  describe '#handle_callback' do
    context 'with url type' do
      let(:qr_type) { 'url' }

      it 'sends URL prompt' do
        expect(api).to receive(:send_message).with(hash_including(
          text: /URL/
        ))
        handler.handle_callback
      end
    end

    context 'with text type' do
      let(:qr_type) { 'text' }

      it 'sends text prompt' do
        expect(api).to receive(:send_message).with(hash_including(
          text: /text you want to embed/
        ))
        handler.handle_callback
      end
    end

    context 'with vcard type' do
      let(:qr_type) { 'vcard' }

      it 'starts vcard input flow' do
        expect(api).to receive(:send_message).with(hash_including(
          text: /Step 1\/4.*first name/
        ))
        handler.handle_callback
      end
    end

    context 'when user has no photo stored' do
      before do
        Bot::UserStateManager.cleanup(chat_id: chat_id)
      end

      let(:qr_type) { 'url' }

      it 'does not send any message' do
        expect(api).not_to receive(:send_message)
        handler.handle_callback
      end
    end
  end
end


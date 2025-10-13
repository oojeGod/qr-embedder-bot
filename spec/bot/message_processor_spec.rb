# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bot::Messages::Processor do
  subject(:processor) { described_class.new(bot: bot, message: message) }

  let(:bot) { double('bot', api: api) }
  let(:api) { double('api') }
  let(:chat_id) { 12_345 }
  let(:chat) { double('chat', id: chat_id) }
  let(:handler) { instance_double(Bot::Messages::Handler) }

  before do
    allow(Bot::Messages::Handler).to receive(:new)
      .with(bot: bot, message: message)
      .and_return(handler)
  end

  after do
    Bot::UserStateManager.cleanup(chat_id: chat_id)
  end

  describe '#process' do
    context 'with photo message' do
      let(:photo) { [double('photo', file_id: 'photo_123')] }
      let(:message) { double('message', chat: chat, photo: photo, text: nil) }

      it 'delegates to handler.handle_photo' do
        expect(handler).to receive(:handle_photo)
        processor.process
      end
    end

    context 'with text message' do
      let(:message) { double('message', chat: chat, photo: nil, text: '/start') }

      it 'delegates to handler.handle_text' do
        expect(handler).to receive(:handle_text)
        processor.process
      end
    end

    context 'with message containing both photo and text' do
      let(:photo) { [double('photo', file_id: 'photo_123')] }
      let(:message) { double('message', chat: chat, photo: photo, text: 'caption') }

      it 'prioritizes photo handling' do
        expect(handler).to receive(:handle_photo)
        expect(handler).not_to receive(:handle_text)
        processor.process
      end
    end

    context 'with message containing neither photo nor text' do
      let(:message) { double('message', chat: chat, photo: nil, text: nil) }

      it 'does not call any handler' do
        expect(handler).not_to receive(:handle_photo)
        expect(handler).not_to receive(:handle_text)
        processor.process
      end

      it 'returns nil' do
        expect(processor.process).to be_nil
      end
    end
  end
end

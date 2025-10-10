# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bot::MessageProcessor do
  subject(:processor) { described_class.new }

  let(:bot) { double('bot', api: api) }
  let(:api) { double('api') }
  let(:chat_id) { 12_345 }
  let(:message) { double('message', chat: double('chat', id: chat_id)) }

  before do
    ENV['TELEGRAM_BOT_TOKEN'] = 'test_token'
  end

  describe '#process' do
    context 'with photo' do
      before do
        allow(message).to receive(:photo).and_return([double(file_id: 'photo_123')])
        allow(message).to receive(:text).and_return(nil)
      end

      it 'sends QR type selection' do
        expect(api).to receive(:send_message)
        processor.process(message, bot)
      end
    end

    context 'with text' do
      before do
        allow(message).to receive(:photo).and_return(nil)
        allow(message).to receive(:text).and_return('https://example.com')
      end

      context 'without photo' do
        it 'asks for photo' do
          expect(api).to receive(:send_message).with(hash_including(text: /photo first/i))
          processor.process(message, bot)
        end
      end

      context 'with photo and QR type selected' do
        before do
          submit_photo_and_select_qr_type
          stub_processing
        end

        it 'processes and sends result', :aggregate_failures do
          expect(api).to receive(:send_message).with(hash_including(text: /Processing/i))
          expect(api).to receive(:send_photo).with(hash_including(caption: /Done/i))
          
          processor.process(message, bot)
        end
      end
    end
  end

  describe '#process_callback' do
    let(:callback) { double('callback', id: 'cbq', data: 'url', message: message) }

    context 'with photo state' do
      before do
        submit_photo
        allow(api).to receive(:answer_callback_query)
      end

      it 'prompts for data' do
        expect(api).to receive(:send_message).with(hash_including(text: /URL/i))
        processor.process_callback(callback, bot)
      end
    end

    context 'without photo state' do
      it 'ignores callback' do
        expect(api).not_to receive(:send_message)
        processor.process_callback(callback, bot)
      end
    end
  end

  private

  def submit_photo
    photo_msg = double('msg', chat: double('chat', id: chat_id), photo: [double(file_id: 'photo_123')], text: nil)
    allow(api).to receive(:send_message)
    processor.process(photo_msg, bot)
  end

  def submit_photo_and_select_qr_type
    submit_photo
    callback = double('callback', id: 'cbq', data: 'url', message: double('msg', chat: double('chat', id: chat_id)))
    allow(api).to receive(:answer_callback_query)
    processor.process_callback(callback, bot)
  end

  def stub_processing
    allow(Bot::PhotoDownloader).to receive(:download).and_return('/tmp/photo.jpg')
    allow(Services::ImageProcessor).to receive(:new).and_return(double(process: '/tmp/result.png'))
    allow(File).to receive(:exist?).and_return(false)
    allow(File).to receive(:open).and_return(double('file'))
  end
end

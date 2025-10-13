# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bot::Callbacks::Processor do
  subject(:processor) { described_class.new(bot: bot, callback_query: callback_query) }

  let(:bot) { double('bot', api: api) }
  let(:api) { double('api') }
  let(:chat_id) { 12_345 }
  let(:callback_id) { 'cbq_123' }
  let(:message) { double('message', chat: double('chat', id: chat_id)) }
  let(:callback_query) { double('callback_query', id: callback_id, data: 'url', message: message) }

  describe '#process_callback' do
    let(:handler) { instance_double(Bot::Callbacks::Handler) }

    before do
      allow(Bot::Callbacks::Handler).to receive(:new)
        .with(bot: bot, callback_query: callback_query)
        .and_return(handler)
      allow(handler).to receive(:handle_callback)
    end

    it 'answers callback query' do
      expect(api).to receive(:answer_callback_query).with(callback_query_id: callback_id)
      processor.process_callback
    end
  end
end


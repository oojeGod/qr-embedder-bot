# frozen_string_literal: true

require_relative '../user_state_manager'
require_relative 'builder'
require_relative '../qr/vcard/builder'
require_relative 'handler'

module Bot
  module Callbacks
    # Main orchestrator for callback processing
    class CallbackProcessor
      def initialize(bot:, callback_query:)
        @bot = bot
        @callback_query = callback_query
      end

      def process_callback
        bot.api.answer_callback_query(callback_query_id: callback_query.id)
        
        handler = Callbacks::CallbackHandler.new(bot: bot, callback_query: callback_query)
        handler.handle_callback
      end

      private

      attr_reader :bot, :callback_query
    end
  end
end

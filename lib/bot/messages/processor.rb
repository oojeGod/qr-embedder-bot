# frozen_string_literal: true

require_relative '../user_state_manager'
require_relative '../callbacks/builder'
require_relative '../qr/vcard/builder'
require_relative '../qr/generator'
require_relative 'handler'

module Bot
  module Messages
    # Main orchestrator for message processing
    class MessageProcessor
      def initialize(bot:, message:)
        @bot = bot
        @message = message
      end

      def process
        handler = Messages::MessageHandler.new(bot: bot, message: message)
        
        return handler.handle_photo if message.photo
        return handler.handle_text if message.text
      end

      private

      attr_reader :bot, :message
    end
  end
end

# frozen_string_literal: true

require_relative '../user_state_manager'
require_relative '../callbacks/callback_builder'
require_relative '../qr/vcard/vcard_builder'
require_relative '../qr/qr_generator'
require_relative 'message_handler'

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

# frozen_string_literal: true

require 'telegram/bot'
require_relative 'messages/message_processor'
require_relative 'callbacks/callback_processor'

module Bot
  # Main bot client that handles Telegram Bot API connection and message routing
  class Client
    class << self
      # Starts the bot and begins listening for messages
      def start
        validate_token!
        
        puts "🤖 Starting QR Telegram Bot..."
        puts "📡 Connecting to Telegram API..."

        Telegram::Bot::Client.run(token) do |bot|
          puts "✅ Bot started successfully!"
          puts "👋 Send /start to begin"
          puts "⏹  Press Ctrl+C to stop\n\n"

          bot.listen { |message| handle_message(bot: bot, message: message) }
        end
      end

      private

      def handle_message(bot:, message:)
        case message
        when Telegram::Bot::Types::CallbackQuery
          processor = Callbacks::CallbackProcessor.new(bot: bot, callback_query: message)
          processor.process_callback
        when Telegram::Bot::Types::Message
          processor = Messages::MessageProcessor.new(bot: bot, message: message)
          processor.process
        end
      rescue StandardError => e
        log_error(e)
      end

      def token
        ENV['TELEGRAM_BOT_TOKEN']
      end

      def validate_token!
        return if token && !token.empty?

        puts "❌ Error: TELEGRAM_BOT_TOKEN not set"
        puts "💡 Please set TELEGRAM_BOT_TOKEN in .env file"
        exit 1
      end

      def log_error(error)
        puts "\n❌ Error occurred: #{error.class}"
        puts "   Message: #{error.message}"
        puts "   Backtrace:\n#{error.backtrace.first(3).join("\n")}\n\n"
      end
    end
  end
end


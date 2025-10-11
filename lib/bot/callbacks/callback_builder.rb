# frozen_string_literal: true

require_relative '../qr/qr_types_configuration'

module Bot
  module Callbacks
    # Builds and sends responses to users
    class CallbackBuilder
      include Qr::QrTypesConfiguration

      MIN_IMAGE_SIZE = 300

      def initialize(bot, chat_id)
        @bot = bot
        @chat_id = chat_id
      end

      def send_welcome
        send_message(welcome_text)
      end

      def send_photo_received
        send_message(photo_received_text, qr_type_keyboard)
      end

      def send_processing
        send_message('🔄 Processing your image...')
      end

      def send_result(result_path)
        raise 'Bot instance required for sending photos' unless bot

        bot.api.send_photo(
          chat_id: chat_id,
          photo: Faraday::UploadIO.new(result_path, 'image/png'),
          caption: result_caption
        )
      end

      def send_error(error)
        send_message(build_error_message(error))
      end

      def send_ask_photo
        send_message('📷 Please send a photo first, then I will ask for QR data.')
      end

      def send_qr_prompt(qr_type)
        prompt_text = QR_TYPES[qr_type][:prompt]
        send_message(prompt_text)
      end

      def send_message(text, reply_markup = nil)
        raise 'Bot instance required for sending messages' unless bot
        
        params = { chat_id: chat_id, text: text }
        params[:reply_markup] = reply_markup if reply_markup
        bot.api.send_message(params)
      end

      private

      attr_reader :bot, :chat_id

      def welcome_text
        "👋 Welcome to QR Embedder Bot!\n\n" \
        "🎨 I embed QR codes that blend with your images.\n\n" \
        "📷 Send me a photo to get started!"
      end

      def photo_received_text
        "📷 Photo received!\n\nWhat would you like to embed in QR code?"
      end

      def result_caption
        "✅ Done! QR code embedded (scannable by camera).\n\n" \
        "📱 Try scanning with your phone camera!"
      end

      def build_error_message(error)
        case error.message
        when /Image is too small/
          "❌ Image too small! Send at least #{MIN_IMAGE_SIZE}x#{MIN_IMAGE_SIZE} pixels."
        when /Data cannot be empty/
          "❌ Data cannot be empty! Send URL, text, or vCard."
        else
          "❌ Error: #{error.message}"
        end
      end
    end
  end
end
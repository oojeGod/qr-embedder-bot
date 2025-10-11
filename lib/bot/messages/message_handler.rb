# frozen_string_literal: true

require_relative '../user_state_manager'
require_relative '../callbacks/response_builder'
require_relative '../qr/vcard/vcard_builder'
require_relative '../qr/vcard/vcard_generator'

module Bot
  module Messages
    # Handles different types of messages
    class MessageHandler
      def initialize(bot, message)
        @bot = bot
        @message = message
      end

      def handle_photo
        chat_id = message.chat.id
        photo = message.photo.last

        state_manager.store_photo(chat_id, photo.file_id)
        response_builder.send_photo_received
      end

      def handle_text
        chat_id = message.chat.id
        text = message.text.strip

        case text
        when '/start'
          response_builder.send_welcome
        else
          if state_manager.in_vcard_flow?(chat_id)
            handle_vcard_text(chat_id)
          elsif state_manager.waiting_for_data?(chat_id)
            handle_qr_data_text(chat_id)
          else
            response_builder.send_ask_photo
          end
        end
      end

      private

      attr_reader :bot, :message

      def state_manager
        @state_manager ||= UserStateManager.new
      end

      def response_builder
        @response_builder ||= Callbacks::CallbackBuilder.new(bot, message.chat.id)
      end

      def handle_vcard_text(chat_id)
        prompt_text = Vcard::VcardBuilder.process_step(chat_id, message.text.strip, state_manager)
        
        if prompt_text
          response_builder.send_message(prompt_text)
        else
          vcard_data = Vcard::VcardBuilder.get_vcard_data(chat_id, state_manager)
          vcard_generator = Vcard::VcardGenerator.new(bot, chat_id, vcard_data)
          vcard_generator.generate_vcard
        end
      end

      def handle_qr_data_text(chat_id)
        qr_data = message.text.strip
        
        qr_generator = Qr::QrGenerator.new(bot, chat_id, qr_data)
        qr_generator.generate
      end
    end
  end
end

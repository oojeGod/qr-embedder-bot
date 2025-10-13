# frozen_string_literal: true

require_relative '../user_state_manager'
require_relative '../callbacks/builder'
require_relative '../qr/vcard/builder'
require_relative '../qr/vcard/generator'

module Bot
  module Messages
    # Handles different types of messages
    class Handler
      def initialize(bot:, message:)
        @bot = bot
        @message = message
      end

      def handle_photo
        chat_id = message.chat.id
        photo = message.photo.last

        UserStateManager.store_photo(chat_id: chat_id, file_id: photo.file_id)
        response_builder.send_photo_received
      end

      def handle_text
        chat_id = message.chat.id
        text = message.text.strip

        case text
        when '/start'
          response_builder.send_welcome
        else
          if UserStateManager.in_vcard_flow?(chat_id: chat_id)
            handle_vcard_text(chat_id)
          elsif UserStateManager.waiting_for_data?(chat_id: chat_id)
            handle_qr_data_text(chat_id)
          else
            response_builder.send_ask_photo
          end
        end
      end

      private

      attr_reader :bot, :message

      def response_builder
        @response_builder ||= Callbacks::Builder.new(bot: bot, chat_id: message.chat.id)
      end

      def handle_vcard_text(chat_id)
        prompt_text = Qr::Vcard::Builder.process_step(chat_id: chat_id, data: message.text.strip, state_manager: UserStateManager)
        
        if prompt_text
          response_builder.send_message(text: prompt_text)
        else
          vcard_data = Qr::Vcard::Builder.get_vcard_data(chat_id: chat_id, state_manager: UserStateManager)
          vcard_generator = Qr::Vcard::Generator.new(bot: bot, chat_id: chat_id, vcard_data: vcard_data)
          vcard_generator.generate_vcard
        end
      end

      def handle_qr_data_text(chat_id)
        qr_data = message.text.strip
        
        qr_generator = Qr::Generator.new(bot: bot, chat_id: chat_id, qr_data: qr_data)
        qr_generator.generate
      end
    end
  end
end

# frozen_string_literal: true

require_relative '../user_state_manager'
require_relative 'callback_builder'
require_relative '../qr/vcard/vcard_builder'
require_relative '../qr/qr_types_configuration'

module Bot
  module Callbacks
    # Handles callback queries from inline keyboards
    class CallbackHandler
      include Qr::QrTypesConfiguration

      def initialize(bot, callback_query)
        @bot = bot
        @callback_query = callback_query
      end

      def handle_callback
        chat_id = callback_query.message.chat.id
        qr_type = callback_query.data
        
        return unless UserStateManager.has_photo?(chat_id)

        UserStateManager.set_qr_type(chat_id, qr_type)
        handle_qr_type_selection(chat_id, qr_type)
      end

      private

      attr_reader :callback_query, :bot

      def response_builder
        @response_builder ||= Callbacks::CallbackBuilder.new(bot, callback_query.message.chat.id)
      end

      def handle_qr_type_selection(chat_id, qr_type)
        if qr_type == 'vcard'
          prompt_text = Qr::Vcard::VcardBuilder.start_input(chat_id, UserStateManager)
          response_builder.send_message(prompt_text)
        else
          response_builder.send_qr_prompt(qr_type)
        end
      end
    end
  end
end
# frozen_string_literal: true

require_relative '../qr_generator'
require_relative 'vcard_builder'
require_relative '../../user_state_manager'
require_relative '../../callbacks/callback_builder'

module Bot
  module Qr
    module Vcard
      # Handles vCard QR code generation
      class VcardGenerator
        def initialize(bot:, chat_id:, vcard_data:)
          @bot = bot
          @chat_id = chat_id
          @vcard_data = vcard_data
        end

        def generate_vcard
          vcard_content = VcardBuilder.build_vcard(data: vcard_data)
          qr_generator = QrGenerator.new(bot: bot, chat_id: chat_id, qr_data: vcard_content)
          qr_generator.generate
        end

        private

        attr_reader :bot, :chat_id, :vcard_data
      end
    end
  end
end

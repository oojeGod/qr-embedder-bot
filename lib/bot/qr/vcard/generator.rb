# frozen_string_literal: true

require_relative '../generator'
require_relative 'builder'
require_relative '../../user_state_manager'
require_relative '../../callbacks/builder'

module Bot
  module Qr
    module Vcard
      # Handles vCard QR code generation
      class Generator
        def initialize(bot:, chat_id:, vcard_data:)
          @bot = bot
          @chat_id = chat_id
          @vcard_data = vcard_data
        end

        def generate_vcard
          vcard_content = Builder.build_vcard(data: vcard_data)
          qr_generator = Qr::Generator.new(bot: bot, chat_id: chat_id, qr_data: vcard_content)
          qr_generator.generate
        end

        private

        attr_reader :bot, :chat_id, :vcard_data
      end
    end
  end
end

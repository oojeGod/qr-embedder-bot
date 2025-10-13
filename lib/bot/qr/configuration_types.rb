# frozen_string_literal: true

module Bot
  module Qr
    # keyboard generation
    module ConfigurationTypes
      QR_TYPES = {
        'url' => { label: '🔗 URL', prompt: 'Send me the URL (e.g., https://example.com):' },
        'text' => { label: '📝 Text', prompt: 'Send me any text you want to embed:' },
        'vcard' => { label: '👤 vCard', prompt: 'Send me vCard contact info:' }
      }.freeze

      def qr_type_keyboard
        @qr_type_keyboard ||= begin
          buttons = QR_TYPES.map do |type, config|
            Telegram::Bot::Types::InlineKeyboardButton.new(
              text: config[:label],
              callback_data: type
            )
          end

          Telegram::Bot::Types::InlineKeyboardMarkup.new(
            inline_keyboard: [buttons]
          )
        end
      end
    end
  end
end

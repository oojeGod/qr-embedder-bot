# frozen_string_literal: true

require 'telegram/bot'

module Bot
  # Processes incoming messages with photo and text handling
  # Manages user state for conversation flow
  class MessageProcessor
    QR_TYPES = {
      'url' => { label: '🔗 URL', prompt: 'Send me the URL (e.g., https://example.com):' },
      'text' => { label: '📝 Text', prompt: 'Send me any text you want to embed:' },
      'vcard' => { label: '👤 vCard', prompt: 'Send me vCard contact info:' }
    }.freeze

    def initialize
      @user_states = {}
    end

    # Processes incoming message
    #
    # @param message [Telegram::Bot::Types::Message] incoming message
    # @param bot [Telegram::Bot::Client] bot instance
    def process(message, bot)
      if message.photo
        handle_photo(message, bot)
      elsif message.text
        handle_text(message, bot)
      end
    end

    # Processes callback from inline keyboard button
    #
    # @param callback_query [Telegram::Bot::Types::CallbackQuery] callback from button
    # @param bot [Telegram::Bot::Client] bot instance
    def process_callback(callback_query, bot)
      chat_id = callback_query.message.chat.id
      qr_type = callback_query.data

      return unless QR_TYPES.key?(qr_type)
      return unless @user_states[chat_id]

      @user_states[chat_id][:qr_type] = qr_type

      bot.api.answer_callback_query(callback_query_id: callback_query.id)
      bot.api.send_message(
        chat_id: chat_id,
        text: QR_TYPES[qr_type][:prompt]
      )
    end

    private

    def handle_photo(message, bot)
      chat_id = message.chat.id
      photo = message.photo.last

      @user_states[chat_id] = { file_id: photo.file_id }

      bot.api.send_message(
        chat_id: chat_id,
        text: "📷 Photo received!\n\nWhat would you like to embed in QR code?",
        reply_markup: qr_type_keyboard
      )
    end

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

    def handle_text(message, bot)
      chat_id = message.chat.id

      if waiting_for_data?(chat_id)
        process_qr_data(message, bot, chat_id)
      else
        ask_for_photo(bot, chat_id)
      end
    end

    def waiting_for_data?(chat_id)
      state = @user_states[chat_id]
      state && state[:qr_type]
    end

    def process_qr_data(message, bot, chat_id)
      send_processing_message(bot, chat_id)

      file_id = @user_states[chat_id][:file_id]
      qr_data = message.text.strip

      file_path = PhotoDownloader.download(bot, file_id)
      result_path = Services::ImageProcessor.new.process(file_path, qr_data)

      send_result(bot, chat_id, result_path)
      @user_states.delete(chat_id)
    ensure
      cleanup_files(file_path, result_path)
    end

    def send_processing_message(bot, chat_id)
      bot.api.send_message(
        chat_id: chat_id,
        text: '🔄 Processing your image with invisible QR code...'
      )
    end

    def send_result(bot, chat_id, result_path)
      bot.api.send_photo(
        chat_id: chat_id,
        photo: File.open(result_path, 'rb'),
        caption: "✅ Done! QR code embedded (invisible to eye, scannable by camera).\n\n" \
                 "📱 Try scanning with your phone camera!"
      )
    end

    def ask_for_photo(bot, chat_id)
      bot.api.send_message(
        chat_id: chat_id,
        text: '📷 Please send a photo first, then I will ask for QR data.'
      )
    end

    def cleanup_files(file_path, result_path)
      File.delete(file_path) if file_path && File.exist?(file_path)
      File.delete(result_path) if result_path && File.exist?(result_path)
    end
  end
end

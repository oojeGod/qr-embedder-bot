# frozen_string_literal: true

require 'telegram/bot'

module Bot
  class MessageProcessor
    QR_TYPES = {
      'url' => { label: '🔗 URL', prompt: 'Send me the URL:' },
      'text' => { label: '📝 Text', prompt: 'Send me any text:' },
      'vcard' => { label: '👤 vCard', prompt: 'vcard_step1' }
    }.freeze

    def initialize
      @user_states = {}
    end

    def process(message, bot)
      if message.photo
        handle_photo(message, bot)
      elsif message.text
        handle_text(message, bot)
      end
    end

    def process_callback(callback_query, bot)
      chat_id = callback_query.message.chat.id
      qr_type = callback_query.data

      return unless QR_TYPES.key?(qr_type) && @user_states[chat_id]

      @user_states[chat_id][:qr_type] = qr_type

      bot.api.answer_callback_query(callback_query_id: callback_query.id)
      
      if qr_type == 'vcard'
        start_vcard_input(bot, chat_id)
      else
        bot.api.send_message(chat_id: chat_id, text: QR_TYPES[qr_type][:prompt])
      end
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
      buttons = QR_TYPES.map do |type, config|
        Telegram::Bot::Types::InlineKeyboardButton.new(
          text: config[:label],
          callback_data: type
        )
      end

      Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [buttons])
    end

    def handle_text(message, bot)
      chat_id = message.chat.id
      text = message.text.strip

      if text == '/start'
        send_welcome_message(bot, chat_id)
      elsif waiting_for_vcard_step?(chat_id)
        process_vcard_step(message, bot, chat_id)
      elsif waiting_for_data?(chat_id)
        process_qr_data(message, bot, chat_id)
      else
        ask_for_photo(bot, chat_id)
      end
    end

    def waiting_for_data?(chat_id)
      state = @user_states[chat_id]
      state && state[:qr_type] && state[:qr_type] != 'vcard'
    end

    def waiting_for_vcard_step?(chat_id)
      state = @user_states[chat_id]
      state && state[:qr_type] == 'vcard' && state[:vcard_step]
    end

    def start_vcard_input(bot, chat_id)
      @user_states[chat_id][:vcard_step] = 'name'
      @user_states[chat_id][:vcard_data] = {}
      
      bot.api.send_message(
        chat_id: chat_id,
        text: "👤 Creating vCard contact...\n\n📝 Step 1/4: What's your first name?"
      )
    end

    def process_vcard_step(message, bot, chat_id)
      step = @user_states[chat_id][:vcard_step]
      data = message.text.strip

      case step
      when 'name'
        @user_states[chat_id][:vcard_data][:first_name] = data
        @user_states[chat_id][:vcard_step] = 'last_name'
        bot.api.send_message(chat_id: chat_id, text: "📝 Step 2/4: What's your last name?")
        
      when 'last_name'
        @user_states[chat_id][:vcard_data][:last_name] = data
        @user_states[chat_id][:vcard_step] = 'phone'
        bot.api.send_message(chat_id: chat_id, text: "📝 Step 3/4: What's your phone number?\n\n💡 Example: +1234567890")
        
      when 'phone'
        @user_states[chat_id][:vcard_data][:phone] = data
        @user_states[chat_id][:vcard_step] = 'email'
        bot.api.send_message(chat_id: chat_id, text: "📝 Step 4/4: What's your email?\n\n💡 Example: john@example.com")
        
      when 'email'
        @user_states[chat_id][:vcard_data][:email] = data
        generate_vcard_qr(bot, chat_id)
      end
    end

    def generate_vcard_qr(bot, chat_id)
      vcard_data = @user_states[chat_id][:vcard_data]
      vcard_content = build_vcard(vcard_data)
      
      send_processing_message(bot, chat_id)

      file_id = @user_states[chat_id][:file_id]
      file_path = PhotoDownloader.download(bot, file_id)
      result_path = Services::ImageProcessor.new.process(file_path, vcard_content, 'vcard')

      send_result(bot, chat_id, result_path)
      @user_states.delete(chat_id)
    rescue ArgumentError => e
      handle_user_error(bot, chat_id, e)
    ensure
      cleanup_files(file_path, result_path)
    end

    def build_vcard(data)
      vcard = "BEGIN:VCARD\n"
      vcard += "FN:#{data[:first_name]} #{data[:last_name]}\n"
      vcard += "TEL:#{data[:phone]}\n" if data[:phone]
      vcard += "EMAIL:#{data[:email]}\n" if data[:email]
      vcard += "END:VCARD"
      vcard
    end

    def process_qr_data(message, bot, chat_id)
      send_processing_message(bot, chat_id)

      file_id = @user_states[chat_id][:file_id]
      qr_data = message.text.strip
      qr_type = @user_states[chat_id][:qr_type]

      file_path = PhotoDownloader.download(bot, file_id)
      result_path = Services::ImageProcessor.new.process(file_path, qr_data, qr_type)

      send_result(bot, chat_id, result_path)
      @user_states.delete(chat_id)
    rescue ArgumentError => e
      handle_user_error(bot, chat_id, e)
    ensure
      cleanup_files(file_path, result_path)
    end

    def send_welcome_message(bot, chat_id)
      bot.api.send_message(
        chat_id: chat_id,
        text: "👋 Welcome to QR Embedder Bot!\n\n" \
              "🎨 I embed QR codes that blend with your images.\n\n" \
              "📷 Send me a photo to get started!"
      )
    end

    def send_processing_message(bot, chat_id)
      bot.api.send_message(
        chat_id: chat_id,
        text: '🔄 Processing your image...'
      )
    end

    def send_result(bot, chat_id, result_path)
      bot.api.send_photo(
        chat_id: chat_id,
        photo: Faraday::UploadIO.new(result_path, 'image/png'),
        caption: "✅ Done! QR code embedded (scannable by camera).\n\n" \
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

    def handle_user_error(bot, chat_id, error)
      message = case error.message
                when /Image is too small/
                  "❌ Image too small! Send at least 300x300 pixels."
                when /Data cannot be empty/
                  "❌ Data cannot be empty! Send URL, text, or vCard."
                else
                  "❌ Error: #{error.message}"
                end

      bot.api.send_message(chat_id: chat_id, text: message)
      @user_states.delete(chat_id)
    end
  end
end

# frozen_string_literal: true

module Bot
  # Manages user state for conversation flow
  class UserStateManager
    def initialize
      @user_states = {}
    end

    # Stores photo file_id for user
    def store_photo(chat_id, file_id)
      @user_states[chat_id] = { file_id: file_id }
    end

    # Sets QR type for user
    def set_qr_type(chat_id, qr_type)
      @user_states[chat_id] ||= {}
      @user_states[chat_id][:qr_type] = qr_type
    end

    # Checks if user is waiting for QR data (non-vcard)
    def waiting_for_data?(chat_id)
      state = @user_states[chat_id]
      state&.dig(:qr_type) && state[:qr_type] != 'vcard'
    end

    # Checks if user is in vcard input flow
    def in_vcard_flow?(chat_id)
      state = @user_states[chat_id]
      state&.dig(:qr_type) == 'vcard' && state[:vcard_step]
    end

    # Gets file_id for user
    def get_file_id(chat_id)
      @user_states[chat_id]&.dig(:file_id)
    end


    # Gets vcard data
    def get_vcard_data(chat_id)
      @user_states[chat_id]&.dig(:vcard_data) || {}
    end

    # Updates vcard data
    def update_vcard_data(chat_id, field, value)
      @user_states[chat_id] ||= {}
      @user_states[chat_id][:vcard_data] ||= {}
      @user_states[chat_id][:vcard_data][field] = value
    end

    # Sets vcard step
    def set_vcard_step(chat_id, step)
      @user_states[chat_id] ||= {}
      @user_states[chat_id][:vcard_step] = step
    end

    # Gets current vcard step
    def get_vcard_step(chat_id)
      @user_states[chat_id]&.dig(:vcard_step)
    end

    # Cleans up user state
    def cleanup(chat_id)
      @user_states.delete(chat_id)
    end

    # Validates if callback is valid for user
    def valid_callback?(qr_type, chat_id)
      @user_states[chat_id] && @user_states[chat_id][:qr_type] != qr_type
    end
  end
end

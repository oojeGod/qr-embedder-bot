# frozen_string_literal: true

module Bot
  module Qr
    module Vcard
      # Handles vCard creation and input flow
      class Builder
        FIELD_LABELS = {
          'name' => "first name",
          'last_name' => "last name", 
          'phone' => "phone number",
          'email' => "email"
        }.freeze

        class << self
          def start_input(chat_id:, state_manager:)
            state_manager.set_vcard_step(chat_id: chat_id, step: 'name')
            state_manager.update_vcard_data(chat_id: chat_id, field: :data, value: {})
            get_field_prompt(field: 'name', step_number: 1)
          end

          def process_step(chat_id:, data:, state_manager:)
            step = state_manager.get_vcard_step(chat_id: chat_id)
            
            case step
            when 'name'
              handle_name_input(chat_id: chat_id, data: data, state_manager: state_manager)
            when 'last_name'
              handle_last_name_input(chat_id: chat_id, data: data, state_manager: state_manager)
            when 'phone'
              handle_phone_input(chat_id: chat_id, data: data, state_manager: state_manager)
            when 'email'
              handle_email_input(chat_id: chat_id, data: data, state_manager: state_manager)
            end
          end

          def get_vcard_data(chat_id:, state_manager:)
            state_manager.get_vcard_data(chat_id: chat_id)
          end

          def build_vcard(data:)
            vcard_lines = [
              "BEGIN:VCARD",
              "FN:#{data[:first_name]} #{data[:last_name]}"
            ]
            
            vcard_lines << "TEL:#{data[:phone]}" if data[:phone]
            vcard_lines << "EMAIL:#{data[:email]}" if data[:email]
            vcard_lines << "END:VCARD"
            
            vcard_lines.join("\n")
          end

          private

          def handle_name_input(chat_id:, data:, state_manager:)
            state_manager.update_vcard_data(chat_id: chat_id, field: :first_name, value: data)
            state_manager.set_vcard_step(chat_id: chat_id, step: 'last_name')
            get_field_prompt(field: 'last_name', step_number: 2)
          end

          def handle_last_name_input(chat_id:, data:, state_manager:)
            state_manager.update_vcard_data(chat_id: chat_id, field: :last_name, value: data)
            state_manager.set_vcard_step(chat_id: chat_id, step: 'phone')
            get_field_prompt(field: 'phone', step_number: 3, hint: "💡 Example: +1234567890")
          end

          def handle_phone_input(chat_id:, data:, state_manager:)
            state_manager.update_vcard_data(chat_id: chat_id, field: :phone, value: data)
            state_manager.set_vcard_step(chat_id: chat_id, step: 'email')
            get_field_prompt(field: 'email', step_number: 4, hint: "💡 Example: john@example.com")
          end

          def handle_email_input(chat_id:, data:, state_manager:)
            state_manager.update_vcard_data(chat_id: chat_id, field: :email, value: data)
            nil
          end

          def get_field_prompt(field:, step_number:, hint: nil)
            text = "📝 Step #{step_number}/4: What's your #{FIELD_LABELS[field]}?"
            text += "\n\n#{hint}" if hint
            text
          end
        end
      end
    end
  end
end

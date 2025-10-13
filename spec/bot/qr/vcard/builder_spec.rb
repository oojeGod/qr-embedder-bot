# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bot::Qr::Vcard::Builder do
  let(:chat_id) { 12_345 }
  let(:state_manager) { Bot::UserStateManager }

  after do
    state_manager.cleanup(chat_id: chat_id)
  end

  describe '.start_input' do
    it 'sets vcard step to name' do
      described_class.start_input(chat_id: chat_id, state_manager: state_manager)
      expect(state_manager.get_vcard_step(chat_id: chat_id)).to eq('name')
    end

    it 'initializes vcard data' do
      described_class.start_input(chat_id: chat_id, state_manager: state_manager)
      expect(state_manager.get_vcard_data(chat_id: chat_id)).to include(data: {})
    end

    it 'returns first name prompt' do
      result = described_class.start_input(chat_id: chat_id, state_manager: state_manager)
      expect(result).to match(/Step 1\/4.*first name/)
    end
  end

  describe '.process_step' do
    context 'when processing name step' do
      before do
        state_manager.set_vcard_step(chat_id: chat_id, step: 'name')
      end

      it 'stores first name' do
        described_class.process_step(chat_id: chat_id, data: 'John', state_manager: state_manager)
        expect(state_manager.get_vcard_data(chat_id: chat_id)[:first_name]).to eq('John')
      end

      it 'advances to last_name step' do
        described_class.process_step(chat_id: chat_id, data: 'John', state_manager: state_manager)
        expect(state_manager.get_vcard_step(chat_id: chat_id)).to eq('last_name')
      end

      it 'returns last name prompt' do
        result = described_class.process_step(chat_id: chat_id, data: 'John', state_manager: state_manager)
        expect(result).to match(/Step 2\/4.*last name/)
      end
    end

    context 'when processing last_name step' do
      before do
        state_manager.set_vcard_step(chat_id: chat_id, step: 'last_name')
      end

      it 'stores last name' do
        described_class.process_step(chat_id: chat_id, data: 'Doe', state_manager: state_manager)
        expect(state_manager.get_vcard_data(chat_id: chat_id)[:last_name]).to eq('Doe')
      end

      it 'advances to phone step' do
        described_class.process_step(chat_id: chat_id, data: 'Doe', state_manager: state_manager)
        expect(state_manager.get_vcard_step(chat_id: chat_id)).to eq('phone')
      end

      it 'returns phone prompt with hint' do
        result = described_class.process_step(chat_id: chat_id, data: 'Doe', state_manager: state_manager)
        expect(result).to match(/Step 3\/4.*phone/)
        expect(result).to match(/Example:/)
      end
    end

    context 'when processing phone step' do
      before do
        state_manager.set_vcard_step(chat_id: chat_id, step: 'phone')
      end

      it 'stores phone' do
        described_class.process_step(chat_id: chat_id, data: '+1234567890', state_manager: state_manager)
        expect(state_manager.get_vcard_data(chat_id: chat_id)[:phone]).to eq('+1234567890')
      end

      it 'advances to email step' do
        described_class.process_step(chat_id: chat_id, data: '+1234567890', state_manager: state_manager)
        expect(state_manager.get_vcard_step(chat_id: chat_id)).to eq('email')
      end

      it 'returns email prompt with hint' do
        result = described_class.process_step(chat_id: chat_id, data: '+1234567890', state_manager: state_manager)
        expect(result).to match(/Step 4\/4.*email/)
        expect(result).to match(/Example:/)
      end
    end

    context 'when processing email step (final)' do
      before do
        state_manager.set_vcard_step(chat_id: chat_id, step: 'email')
      end

      it 'stores email' do
        described_class.process_step(chat_id: chat_id, data: 'john@example.com', state_manager: state_manager)
        expect(state_manager.get_vcard_data(chat_id: chat_id)[:email]).to eq('john@example.com')
      end

      it 'returns nil to indicate completion' do
        result = described_class.process_step(chat_id: chat_id, data: 'john@example.com', state_manager: state_manager)
        expect(result).to be_nil
      end
    end
  end

  describe '.get_vcard_data' do
    it 'retrieves vcard data from state manager' do
      state_manager.update_vcard_data(chat_id: chat_id, field: :first_name, value: 'Jane')
      result = described_class.get_vcard_data(chat_id: chat_id, state_manager: state_manager)
      expect(result[:first_name]).to eq('Jane')
    end
  end

  describe '.build_vcard' do
    let(:vcard_data) do
      {
        first_name: 'John',
        last_name: 'Doe',
        phone: '+1234567890',
        email: 'john@example.com'
      }
    end

    it 'builds valid vCard format' do
      vcard = described_class.build_vcard(data: vcard_data)
      expect(vcard).to include('BEGIN:VCARD')
      expect(vcard).to include('END:VCARD')
    end

    it 'includes full name' do
      vcard = described_class.build_vcard(data: vcard_data)
      expect(vcard).to include('FN:John Doe')
    end

    it 'includes phone number' do
      vcard = described_class.build_vcard(data: vcard_data)
      expect(vcard).to include('TEL:+1234567890')
    end

    it 'includes email' do
      vcard = described_class.build_vcard(data: vcard_data)
      expect(vcard).to include('EMAIL:john@example.com')
    end

    context 'when phone is missing' do
      let(:vcard_data) do
        {
          first_name: 'John',
          last_name: 'Doe',
          email: 'john@example.com'
        }
      end

      it 'does not include phone field' do
        vcard = described_class.build_vcard(data: vcard_data)
        expect(vcard).not_to include('TEL:')
      end
    end

    context 'when email is missing' do
      let(:vcard_data) do
        {
          first_name: 'John',
          last_name: 'Doe',
          phone: '+1234567890'
        }
      end

      it 'does not include email field' do
        vcard = described_class.build_vcard(data: vcard_data)
        expect(vcard).not_to include('EMAIL:')
      end
    end

    context 'with minimal data' do
      let(:vcard_data) do
        {
          first_name: 'John',
          last_name: 'Doe'
        }
      end

      it 'builds valid vCard with name only', :aggregate_failures do
        vcard = described_class.build_vcard(data: vcard_data)
        expect(vcard).to include('BEGIN:VCARD')
        expect(vcard).to include('FN:John Doe')
        expect(vcard).to include('END:VCARD')
        expect(vcard).not_to include('TEL:')
        expect(vcard).not_to include('EMAIL:')
      end
    end
  end
end


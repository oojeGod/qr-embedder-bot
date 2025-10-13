# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bot::UserStateManager do
  let(:chat_id) { 12_345 }

  after do
    described_class.cleanup(chat_id: chat_id)
  end

  describe '.store_photo' do
    let(:file_id) { 'photo_file_id_123' }

    it 'stores photo file_id for user' do
      described_class.store_photo(chat_id: chat_id, file_id: file_id)
      expect(described_class.get_file_id(chat_id: chat_id)).to eq(file_id)
    end

    it 'creates new state for user' do
      described_class.store_photo(chat_id: chat_id, file_id: file_id)
      expect(described_class.has_photo?(chat_id: chat_id)).to be_truthy
    end
  end

  describe '.waiting_for_data?' do
    context 'when user has qr_type set (non-vcard)' do
      before do
        described_class.set_qr_type(chat_id: chat_id, qr_type: 'url')
      end

      it 'returns true' do
        expect(described_class.waiting_for_data?(chat_id: chat_id)).to be_truthy
      end
    end

    context 'when user has vcard qr_type' do
      before do
        described_class.set_qr_type(chat_id: chat_id, qr_type: 'vcard')
      end

      it 'returns false' do
        expect(described_class.waiting_for_data?(chat_id: chat_id)).to be_falsey
      end
    end

    context 'when user has no qr_type' do
      it 'returns false' do
        expect(described_class.waiting_for_data?(chat_id: chat_id)).to be_falsey
      end
    end

    context 'when user has no state' do
      it 'returns false' do
        expect(described_class.waiting_for_data?(chat_id: chat_id)).to be_falsey
      end
    end
  end

  describe '.in_vcard_flow?' do
    context 'when user has vcard qr_type and vcard_step' do
      before do
        described_class.set_qr_type(chat_id: chat_id, qr_type: 'vcard')
        described_class.set_vcard_step(chat_id: chat_id, step: 'name')
      end

      it 'returns true' do
        expect(described_class.in_vcard_flow?(chat_id: chat_id)).to be_truthy
      end
    end

    context 'when user has vcard qr_type but no vcard_step' do
      before do
        described_class.set_qr_type(chat_id: chat_id, qr_type: 'vcard')
      end

      it 'returns false' do
        expect(described_class.in_vcard_flow?(chat_id: chat_id)).to be_falsey
      end
    end

    context 'when user has different qr_type' do
      before do
        described_class.set_qr_type(chat_id: chat_id, qr_type: 'url')
        described_class.set_vcard_step(chat_id: chat_id, step: 'name')
      end

      it 'returns false' do
        expect(described_class.in_vcard_flow?(chat_id: chat_id)).to be_falsey
      end
    end
  end

  describe '.get_file_id' do
    context 'when user has stored photo' do
      let(:file_id) { 'photo_123' }

      before do
        described_class.store_photo(chat_id: chat_id, file_id: file_id)
      end

      it 'returns file_id' do
        expect(described_class.get_file_id(chat_id: chat_id)).to eq(file_id)
      end
    end

    context 'when user has no state' do
      it 'returns nil' do
        expect(described_class.get_file_id(chat_id: chat_id)).to be_nil
      end
    end
  end

  describe '.get_vcard_data' do
    context 'when user has vcard data' do
      before do
        described_class.update_vcard_data(chat_id: chat_id, field: :first_name, value: 'John')
        described_class.update_vcard_data(chat_id: chat_id, field: :last_name, value: 'Doe')
      end

      it 'returns vcard data hash' do
        expect(described_class.get_vcard_data(chat_id: chat_id)).to eq(
          first_name: 'John',
          last_name: 'Doe'
        )
      end
    end

    context 'when user has no vcard data' do
      it 'returns empty hash' do
        expect(described_class.get_vcard_data(chat_id: chat_id)).to eq({})
      end
    end
  end

  describe '.update_vcard_data' do
    it 'updates vcard data field' do
      described_class.update_vcard_data(chat_id: chat_id, field: :first_name, value: 'Jane')
      expect(described_class.get_vcard_data(chat_id: chat_id)[:first_name]).to eq('Jane')
    end

    it 'creates vcard_data if not exists' do
      described_class.update_vcard_data(chat_id: chat_id, field: :email, value: 'test@example.com')
      expect(described_class.get_vcard_data(chat_id: chat_id)).to include(email: 'test@example.com')
    end
  end

  describe '.set_vcard_step' do
    it 'sets vcard step' do
      described_class.set_vcard_step(chat_id: chat_id, step: 'phone')
      expect(described_class.get_vcard_step(chat_id: chat_id)).to eq('phone')
    end
  end

  describe '.get_vcard_step' do
    context 'when vcard step is set' do
      before do
        described_class.set_vcard_step(chat_id: chat_id, step: 'email')
      end

      it 'returns current step' do
        expect(described_class.get_vcard_step(chat_id: chat_id)).to eq('email')
      end
    end

    context 'when vcard step is not set' do
      it 'returns nil' do
        expect(described_class.get_vcard_step(chat_id: chat_id)).to be_nil
      end
    end
  end

  describe '.has_photo?' do
    context 'when user has stored photo' do
      before do
        described_class.store_photo(chat_id: chat_id, file_id: 'photo_123')
      end

      it 'returns true' do
        expect(described_class.has_photo?(chat_id: chat_id)).to be_truthy
      end
    end

    context 'when user has no photo' do
      it 'returns false' do
        expect(described_class.has_photo?(chat_id: chat_id)).to be_falsey
      end
    end

    context 'when user has no state' do
      it 'returns false' do
        expect(described_class.has_photo?(chat_id: chat_id)).to be_falsey
      end
    end
  end

  describe '.cleanup' do
    before do
      described_class.store_photo(chat_id: chat_id, file_id: 'photo_123')
      described_class.set_qr_type(chat_id: chat_id, qr_type: 'url')
    end

    it 'removes user state' do
      described_class.cleanup(chat_id: chat_id)
      expect(described_class.has_photo?(chat_id: chat_id)).to be_falsey
    end
  end
end


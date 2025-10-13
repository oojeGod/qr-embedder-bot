# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bot::Qr::Vcard::Generator do
  subject(:generator) { described_class.new(bot: bot, chat_id: chat_id, vcard_data: vcard_data) }

  let(:bot) { double('bot', api: api) }
  let(:api) { double('api') }
  let(:chat_id) { 12_345 }
  let(:vcard_data) do
    {
      first_name: 'John',
      last_name: 'Doe',
      phone: '+1234567890',
      email: 'john@example.com'
    }
  end

  describe '#generate_vcard' do
    let(:vcard_content) do
      "BEGIN:VCARD\nFN:John Doe\nTEL:+1234567890\nEMAIL:john@example.com\nEND:VCARD"
    end
    let(:qr_generator) { instance_double(Bot::Qr::Generator) }
    let(:result_path) { '/tmp/result.png' }

    before do
      allow(Bot::Qr::Vcard::Builder).to receive(:build_vcard)
        .with(data: vcard_data)
        .and_return(vcard_content)
      allow(Bot::Qr::Generator).to receive(:new)
        .with(bot: bot, chat_id: chat_id, qr_data: vcard_content)
        .and_return(qr_generator)
      allow(qr_generator).to receive(:generate).and_return(result_path)
    end

    it 'builds vcard from data' do
      expect(Bot::Qr::Vcard::Builder).to receive(:build_vcard).with(data: vcard_data)
      generator.generate_vcard
    end

    it 'creates QR generator with vcard content' do
      expect(Bot::Qr::Generator).to receive(:new).with(
        bot: bot,
        chat_id: chat_id,
        qr_data: vcard_content
      )
      generator.generate_vcard
    end

    it 'calls generate on QR generator' do
      expect(qr_generator).to receive(:generate).and_return(result_path)
      generator.generate_vcard
    end

    it 'returns result from QR generator' do
      expect(generator.generate_vcard).to eq(result_path)
    end
  end
end


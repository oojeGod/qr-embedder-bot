# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bot::PhotoDownloader do
  subject(:downloader) { described_class.new(bot: bot, file_id: file_id) }

  let(:bot) { double('bot', api: api) }
  let(:api) { double('api') }
  let(:file_id) { 'file_123' }
  let(:file_path) { 'photos/photo.jpg' }
  let(:file_size) { 1024 * 1024 } # 1 MB
  let(:token) { 'test_token_123' }

  before do
    ENV['TELEGRAM_BOT_TOKEN'] = token
    ENV['TEMP_FOLDER'] = './tmp'
    FileUtils.mkdir_p('./tmp') unless Dir.exist?('./tmp')
  end

  after do
    Dir.glob('./tmp/photo_*.jpg').each { |file| File.delete(file) if File.exist?(file) }
  end

  describe '#download' do
    let(:file_info) do
      {
        'result' => {
          'file_path' => file_path,
          'file_size' => file_size
        }
      }
    end
    let(:file_url) { "https://api.telegram.org/file/bot#{token}/#{file_path}" }
    let(:file_content) { 'fake_image_content' }

    before do
      allow(api).to receive(:get_file).with(file_id: file_id).and_return(file_info)
      stub_request(:get, file_url).to_return(status: 200, body: file_content)
    end

    context 'with valid file' do
      it 'downloads file successfully' do
        result = downloader.download
        expect(File).to exist(result)
      end

      it 'returns local file path' do
        result = downloader.download
        expect(result).to match(%r{./tmp/photo_\d+_\d+\.jpg})
      end

      it 'saves file content' do
        result = downloader.download
        expect(File.read(result)).to eq(file_content)
      end

      it 'preserves file extension' do
        result = downloader.download
        expect(File.extname(result)).to eq('.jpg')
      end
    end

    context 'when file has no extension' do
      let(:file_path) { 'photos/photo' }

      it 'uses .jpg as default extension' do
        result = downloader.download
        expect(File.extname(result)).to eq('.jpg')
      end
    end

    context 'when file size exceeds maximum' do
      let(:file_size) { 11 * 1024 * 1024 } # 11 MB

      it 'raises error' do
        expect { downloader.download }.to raise_error(/File is too large/)
      end

      it 'does not download file' do
        expect { downloader.download }.to raise_error
        expect(a_request(:get, file_url)).not_to have_been_made
      end
    end

    context 'when download fails' do
      before do
        stub_request(:get, file_url).to_return(status: 404)
      end

      it 'raises error with descriptive message' do
        expect { downloader.download }.to raise_error(/Failed to download photo/)
      end
    end

    context 'when network timeout occurs' do
      before do
        stub_request(:get, file_url).to_timeout
      end

      it 'raises error with timeout message' do
        expect { downloader.download }.to raise_error(/Failed to download photo/)
      end
    end

    context 'when temp folder does not exist' do
      before do
        ENV['TEMP_FOLDER'] = './tmp/test_folder'
        FileUtils.rm_rf('./tmp/test_folder') if Dir.exist?('./tmp/test_folder')
      end

      after do
        FileUtils.rm_rf('./tmp/test_folder') if Dir.exist?('./tmp/test_folder')
      end

      it 'creates temp folder' do
        downloader.download
        expect(Dir).to exist('./tmp/test_folder')
      end
    end
  end
end


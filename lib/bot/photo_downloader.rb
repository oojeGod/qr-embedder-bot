# frozen_string_literal: true

require 'open-uri'
require 'fileutils'

module Bot
  # Downloads photos from Telegram servers
  class PhotoDownloader
    MAX_FILE_SIZE = 10 * 1024 * 1024 # 10 MB

    def initialize(bot, file_id)
      @bot = bot
      @file_id = file_id
    end

    def download
      file_info = bot.api.get_file(file_id: file_id)
      file_path = file_info.dig('result', 'file_path')
      file_size = file_info.dig('result', 'file_size')

      validate_file_size!(file_size)

      file_url = build_file_url(file_path)
      download_to_file(file_url, file_path)
    rescue OpenURI::HTTPError, Timeout::Error => e
      raise "Failed to download photo: #{e.message}"
    end

    private

    attr_reader :bot, :file_id

    def validate_file_size!(file_size)
      return unless file_size && file_size > MAX_FILE_SIZE

      raise "File is too large (max #{MAX_FILE_SIZE / 1024 / 1024}MB)"
    end

    def build_file_url(file_path)
      token = ENV.fetch('TELEGRAM_BOT_TOKEN')
      "https://api.telegram.org/file/bot#{token}/#{file_path}"
    end

    def download_to_file(file_url, file_path)
      extension = File.extname(file_path)
      extension = '.jpg' if extension.empty?

      tmp_dir = ENV.fetch('TEMP_FOLDER', './tmp')
      FileUtils.mkdir_p(tmp_dir) unless Dir.exist?(tmp_dir)

      local_path = File.join(tmp_dir, "photo_#{Time.now.to_i}_#{rand(10000)}#{extension}")

      File.open(local_path, 'wb') do |file|
        URI.open(file_url, 'rb', read_timeout: 30) do |remote_file|
          file.write(remote_file.read)
        end
      end

      local_path
    end
  end
end

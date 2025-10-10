# frozen_string_literal: true

require 'tempfile'
require 'open-uri'

module Bot
  # Downloads photos from Telegram servers
  class PhotoDownloader
    MAX_FILE_SIZE = 10 * 1024 * 1024 # 10 MB

    class << self
      def download(bot, file_id)
      file_info = bot.api.get_file(file_id: file_id)
      file_path = file_info.dig('result', 'file_path')
      file_size = file_info.dig('result', 'file_size')

      validate_file_size!(file_size)

      file_url = build_file_url(file_path)
      download_to_tempfile(file_url, file_path)
    rescue OpenURI::HTTPError, Timeout::Error => e
      raise "Failed to download photo: #{e.message}"
      end

      private

      def validate_file_size!(file_size)
      return unless file_size && file_size > MAX_FILE_SIZE

      raise "File is too large (max #{MAX_FILE_SIZE / 1024 / 1024}MB)"
    end

    def build_file_url(file_path)
      token = ENV.fetch('TELEGRAM_BOT_TOKEN')
      "https://api.telegram.org/file/bot#{token}/#{file_path}"
    end

    def download_to_tempfile(file_url, file_path)
      extension = File.extname(file_path)
      extension = '.jpg' if extension.empty?

      temp_file = Tempfile.new(['photo', extension])
      temp_file.binmode

      URI.open(file_url, 'rb', read_timeout: 30) do |remote_file|
        temp_file.write(remote_file.read)
      end

        temp_file.close
        temp_file.path
      end
    end
  end
end

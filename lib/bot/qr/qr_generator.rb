# frozen_string_literal: true

require_relative '../photo_downloader'
require_relative '../../services/image_processor'
require_relative '../user_state_manager'
require_relative '../callbacks/callback_builder'

module Bot
  module Qr
    # Handles QR code generation and image processing
    class QrGenerator
      def initialize(bot:, chat_id:, qr_data:)
        @bot = bot
        @chat_id = chat_id
        @qr_data = qr_data
      end

      def generate
        response_builder.send_processing

        file_id = UserStateManager.get_file_id(chat_id: chat_id)
        photo_downloader = PhotoDownloader.new(bot: bot, file_id: file_id)
        file_path = photo_downloader.download
        image_processor = Services::ImageProcessor.new(image_path: file_path, qr_data: qr_data)
        result_path = image_processor.process

        response_builder.send_result(result_path: result_path)
        UserStateManager.cleanup(chat_id: chat_id)
        
        result_path
      rescue ArgumentError => e
        response_builder.send_error(error: e)
        UserStateManager.cleanup(chat_id: chat_id)
        raise
      ensure
        cleanup_files(file_path, result_path)
      end

      private

      attr_reader :bot, :chat_id, :qr_data

      def response_builder
        @response_builder ||= Callbacks::CallbackBuilder.new(bot: bot, chat_id: chat_id)
      end

      def cleanup_files(file_path, result_path)
        File.delete(file_path) if file_path && File.exist?(file_path)
        File.delete(result_path) if result_path && File.exist?(result_path)
      end
    end
  end
end

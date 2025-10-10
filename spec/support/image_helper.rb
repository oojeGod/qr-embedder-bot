# frozen_string_literal: true

require 'mini_magick'

module ImageHelper
  # Creates test image with specified size and color
  #
  # @param size [Integer] width and height of the square image
  # @param color [String] hex color code (default: #e0e0e0)
  # @return [String] path to created image
  def create_test_image(size: 500, color: '#e0e0e0')
    path = File.join(Dir.tmpdir, "test_#{Time.now.to_i}_#{rand(1000)}.png")
    
    MiniMagick::Tool::Convert.new do |convert|
      convert.size "#{size}x#{size}"
      convert << "xc:#{color}"
      convert << path
    end
    
    path
  end
end

RSpec.configure do |config|
  config.include ImageHelper
end


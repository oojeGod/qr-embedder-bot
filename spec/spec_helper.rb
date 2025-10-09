# frozen_string_literal: true

require 'webmock/rspec'

Dir[File.join(__dir__, '..', 'lib', '**', '*.rb')].sort.each { |file| require file }

# Load support files
Dir[File.join(__dir__, 'support', '**', '*.rb')].sort.each { |file| require file }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  WebMock.disable_net_connect!(allow_localhost: true)

  config.disable_monkey_patching!

  config.order = :random
end
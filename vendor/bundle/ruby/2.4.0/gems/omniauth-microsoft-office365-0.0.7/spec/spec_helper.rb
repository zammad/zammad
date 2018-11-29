$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require "pry"
require 'omniauth-microsoft-office365'

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
  config.expose_dsl_globally = false
  config.profile_examples = 3
  config.order = :random
  Kernel.srand config.seed
end

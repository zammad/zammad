$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH << File.join(File.dirname(__FILE__))

# External
require 'rubygems'
require 'rspec'
require 'pry'
require 'webmock/rspec'

# Library
require 'clearbit'

Dir[File.expand_path('spec/support/**/*.rb')].each { |file| require file }

RSpec.configure do |config|
  config.include Spec::Support::Helpers
  config.order = 'random'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before :each do
    Clearbit.key = nil
  end
end

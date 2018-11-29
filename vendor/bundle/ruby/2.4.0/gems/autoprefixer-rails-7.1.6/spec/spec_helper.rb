ENV['RAILS_ENV'] ||= 'test'

require_relative 'app/config/environment'
require_relative '../lib/autoprefixer-rails'

require 'rspec/rails'

STDERR.puts "ExecJS runtime is #{ExecJS.runtime.class}"

RSpec.configure do |c|
  c.filter_run_excluding not_jruby: RUBY_PLATFORM == 'java'
end

def sprockets_4?
  Gem::Version.new(Sprockets::VERSION) > Gem::Version.new("4.0.x")
end

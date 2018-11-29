require 'rspec'
require 'simplecov'
require 'simplecov-json'
require 'codeclimate-test-reporter'

SimpleCov.configure do
  root File.join(File.dirname(__FILE__), '..')
  project_name 'Ruby JWT - Ruby JSON Web Token implementation'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter
  ])

  add_filter 'spec'
end

SimpleCov.start if ENV['COVERAGE']
CodeClimate::TestReporter.start if ENV['CODECLIMATE_REPO_TOKEN']

CERT_PATH = File.join(File.dirname(__FILE__), 'fixtures', 'certs')

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'
end

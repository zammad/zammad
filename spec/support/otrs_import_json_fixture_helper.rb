# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module OtrsImportJsonFixtureHelper
  def json_fixture(file)
    JSON.parse(File.read("spec/fixtures/#{file}.json"))
  end
end

RSpec.configure do |config|
  # Zammad specific helpers
  config.include OtrsImportJsonFixtureHelper

  # skip OtrsImportJsonFixtureHelper functions in the backtraces to lower noise
  config.backtrace_exclusion_patterns << %r{/spec/spec_helper/}
end

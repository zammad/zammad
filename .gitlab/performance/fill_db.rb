#!/usr/bin/env ruby
# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails'

def run
  ensure_test_data_present
end

def ensure_test_data_present
  puts 'Ensuring test data with 15k tickets is present…'

  # Speed up the import
  Setting.set('import_mode', true)

  suppress_output do
    FillDb.load(
      agents:        100,
      customers:     4000,
      groups:        80,
      organizations: 400,
      overviews:     4,
      tickets:       15_000,
      nice:          0,
    )
  end

  Setting.set('import_mode', false)
end

def suppress_output
  original_stdout = $stdout.clone
  $stdout.reopen(File.new(File::NULL, 'w'))
  yield
ensure
  $stdout.reopen(original_stdout)
end

run

#!/usr/bin/env ruby
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Removes all browser test files which do not belong to the given slice, so that each
#   parallel CI job only runs its own share of the suite.
#
# Usage: script/build/test_slice_tests.rb <slice> <slices>
#
# The files are distributed based on their measured runtime from
#   .gitlab/ci/timings/minitest.yml, files without a measurement get the average
#   runtime of the measured ones.

require 'fileutils'
require 'yaml'

TIMINGS_FILE = ENV.fetch('CI_TEST_TIMINGS_FILE', '.gitlab/ci/timings/minitest.yml')

# The first slice runs against a system without the auto wizard, which is performed by
#   its own test. Therefore these tests can only run in this slice.
FIRST_SLICE_FILES = %w[
  test/browser/aaa_auto_wizard_base_setup_test.rb
  test/browser/agent_navigation_and_title_test.rb
  test/browser/agent_organization_profile_test.rb
  test/browser/manage_test.rb
  test/browser/taskbar_session_test.rb
  test/browser/taskbar_task_test.rb
].freeze

# Creates additional agents and groups which the tests of the other slices rely on,
#   therefore it runs in each of them.
SHARED_STATE_FILE = 'test/browser/abb_one_group_test.rb'.freeze

slice  = ARGV[0].to_i
slices = (ARGV[1] || 8).to_i

if slice < 1 || slice > slices
  abort "ERROR: invalid slice #{ARGV[0].inspect} - 1..#{slices} is available"
end

timings = File.exist?(TIMINGS_FILE) ? YAML.load_file(TIMINGS_FILE) : {}
average = timings.values.sum / timings.size.to_f if timings.any?

all_files = Dir['test/browser/*_test.rb']

def slice_files(files, timings, average, slices)
  # The first slice is fixed, so only the remaining slices take part in the distribution.
  totals  = Array.new(slices - 1, 0.0)
  buckets = Array.new(slices - 1) { [] }

  weights = {}
  files.each { |file| weights[file] = timings[file] || average || File.size(file) }

  # Longest-processing-time-first: assign the next biggest file to the slice with the
  #   least work assigned so far.
  weights.sort_by { |file, weight| [-weight, file] }.each do |file, weight|
    index = (0...buckets.size).min_by { |bucket| [totals[bucket], bucket] }

    totals[index] += weight
    buckets[index] << file
  end

  buckets
end

if slice == 1
  puts 'slicing: first slice, running the tests which expect a system without auto wizard'

  FileUtils.cp('contrib/auto_wizard_test.json', 'auto_wizard.json')

  keep_files = FIRST_SLICE_FILES
else
  distributed = slice_files(all_files - FIRST_SLICE_FILES - [SHARED_STATE_FILE], timings, average, slices)

  keep_files = distributed[slice - 2] + [SHARED_STATE_FILE]
end

(all_files - keep_files).each { |file| File.delete(file) }

puts "slicing: running #{keep_files.size} of #{all_files.size} browser test files in slice #{slice}/#{slices}:"
keep_files.sort.each { |file| puts "  #{file}" }

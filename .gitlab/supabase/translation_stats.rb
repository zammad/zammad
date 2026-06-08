#!/usr/bin/env ruby
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require_relative 'supabase'

def translation_stats
  require 'poparser'

  # Load YAML directly to avoid db seeding. We want the stats from the code files.
  locales = YAML.load_file(Rails.root.join('config', 'locales.yml')).select do |locale|
    locale['active'] && %w[en-us sr-latn-rs].exclude?(locale['locale'])
  end

  locales.map do |locale|
    file = Rails.root.join("i18n/zammad.#{locale['locale']}.po")
    po_entries = PoParser.parse_file(file).entries
    translated_count = po_entries.count(&:translated?)
    {
      locale:                         locale['locale'],
      locale_name:                    locale['name'],
      branch:                         ENV['CI_COMMIT_REF_NAME'],
      version:                        ENV['CI_COMMIT_REF_NAME'] == 'develop' ? '' : Version.get,
      strings:                        po_entries.count,
      strings_translated:             translated_count,
      translation_completion_percent: (translated_count * 100.0 / po_entries.count).to_i,
      test_data:                      ENV['SUPABASE_TEST'].present? || false,
    }
  end
end

def run
  if ENV['CI_COMMIT_REF_NAME'].blank?
    puts 'The required environment variable CI_COMMIT_REF_NAME is not set. Exiting.'
    exit 1
  end

  puts "Collecting translation stats for branch #{ENV['CI_COMMIT_REF_NAME']}…"
  payload = translation_stats
  puts 'Done.'

  puts 'Submitting to supabase…'
  pp payload
  Supabase.submit('zammad_translation_stats', payload)
  puts 'Done.'
end

run

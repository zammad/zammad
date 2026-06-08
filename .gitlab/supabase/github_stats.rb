#!/usr/bin/env ruby
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require_relative 'supabase'

BASE_URI = 'https://api.github.com/search/issues?q=repo:zammad/zammad+'.freeze

def get_total_count(query)
  if ENV['GITHUB_APITOKEN'].blank?
    raise 'The required environment variable GITHUB_APITOKEN is not set. Exiting.'
  end

  headers = {
    'Authorization' => "Bearer #{ENV['GITHUB_APITOKEN']}",
  }

  res = Net::HTTP.get_response(URI("#{BASE_URI}#{query}"), headers)

  return JSON.parse(res.body)['total_count'] if res.is_a?(Net::HTTPSuccess)

  raise "GitHub request failed: #{res.code} #{res.message} #{res.body}"
end

def github_stats
  {
    issue_count_all:    get_total_count('is:issue'),
    issue_count_open:   get_total_count('is:issue state:open'),
    issue_count_closed: get_total_count('is:issue state:closed'),
    bug_count_all:      get_total_count('is:issue type:bug'),
    bug_count_open:     get_total_count('is:issue state:open type:bug'),
    bug_count_closed:   get_total_count('is:issue state:closed type:bug'),
    story_count_all:    get_total_count('is:issue type:story'),
    story_count_open:   get_total_count('is:issue state:open type:story'),
    story_count_closed: get_total_count('is:issue state:closed type:story'),
    epic_count_all:     get_total_count('is:issue type:epic'),
    epic_count_open:    get_total_count('is:issue state:open type:epic'),
    epic_count_closed:  get_total_count('is:issue state:closed type:epic'),
    pr_count_all:       get_total_count('is:pr'),
    pr_count_open:      get_total_count('is:pr state:open'),
    pr_count_closed:    get_total_count('is:pr state:closed'),
    test_data:          ENV['SUPABASE_TEST'].present? || false,
  }
end

def run
  puts 'Collecting GitHub stats…'
  payload = github_stats
  puts JSON.pretty_generate(payload)
  puts 'Done.'

  puts 'Submitting to supabase…'
  Supabase.submit('zammad_github_stats', payload)
  puts 'Done.'
end

run

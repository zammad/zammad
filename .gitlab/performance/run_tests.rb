#!/usr/bin/env ruby
# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails'

def run
  puts "# Zammad Performance Tests\n\n"
  run_tests!
end

def run_tests!
  puts 'Run test scenarios…'
  [].tap do |results|
    run_test_scenarios(results:)

    if results.any? { |r| r[:failed] }
      puts 'Tests failed.'
      exit 1
    end

    puts 'All tests were successful.'
  end
end

def run_test_scenarios(results:)
  agent = User.with_permissions('ticket.agent').first

  expect(title: 'assets:precompile', max_time: 120, max_sql_queries: nil, results:) do
    system('RAILS_ENV=production bundle exec rails assets:precompile > /dev/null 2>&1', exception: true)
  end

  max_index_queries = version_oldstable? ? 70 : 35
  expect(title: 'Ticket::Overviews.index', max_time: 1, max_sql_queries: max_index_queries, results:) do
    Ticket::Overviews.index(agent)
  end

  expect(title: 'Ticket::Overviews.all', max_time: 0.05, max_sql_queries: 5, results:) do
    Ticket::Overviews.all(current_user: agent)
  end

  max_overview_list_time    = 20
  max_overview_list_queries = 25_000
  puts "Current ticket count: #{Ticket.count}"
  expect(title: 'Sessions::Backend::TicketOverviewList#push', max_time: max_overview_list_time, max_sql_queries: max_overview_list_queries, results:) do
    Sessions::Backend::TicketOverviewList.new(agent, {}).push
  end
end

def version_oldstable?
  Version.get.match?(%r{^6\.0\.})
end

def expect(title:, max_time:, max_sql_queries:, results:, &block)

  ActiveRecord::Base.connection.query_cache.clear
  Rails.cache.clear

  sql_queries = 0
  failed      = false
  callback = ->(_name, _start, _finish, _id, payload) { sql_queries += 1 if !payload[:cached] }
  time = Benchmark.measure do
    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &block)
  end
  puts "  #{title}: #{time.real}s (#{sql_queries} queries)"

  if max_time && time.real > max_time
    puts "    ERROR: took #{time.real}s, rather than expected maximum of #{max_time}s"
    failed = true
  end

  if max_sql_queries && sql_queries > max_sql_queries
    puts "    ERROR: caused #{sql_queries} SQL queries, rather than expected maximum of #{max_sql_queries}"
    failed = true
  end

  results.push({ title:, max_time:, time: time.real, max_sql_queries:, sql_queries:, failed: })
end

run

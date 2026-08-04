#!/usr/bin/env ruby
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Refreshes the test timings in .gitlab/ci/timings/ from a CI pipeline, which are used to
#   distribute the test files evenly over the parallel CI jobs.
#
# Usage: GITLAB_TOKEN=… script/build/update_test_timings.rb <pipeline-id>
#
# Use a pipeline which ran the complete test suite, otherwise the missing files fall back
#   to an estimation based on their file size.
#
# The runtimes are read from the job logs (see .gitlab/print_test_timings.sh) instead of
#   job artifacts, to avoid uploading artifacts of successful jobs just for this purpose.

require 'json'
require 'net/http'
require 'uri'
require 'yaml'

API_URL = ENV.fetch('CI_API_V4_URL', 'https://git.zammad.com/api/v4')
PROJECT = ENV.fetch('CI_PROJECT_ID', 'zammad%2Fzammad')

# Which jobs provide the runtimes of which timings file.
TIMINGS_FILES = {
  '.gitlab/ci/timings/rspec.yml' => %r{^(rspec|capybara:chrome) \d+/\d+$},
}.freeze

# Lines of the recorded timings YAML in the job log, e.g. 'spec/models/user_spec.rb: 12.3'.
TIMING_LINE = %r{^(?<file>spec/\S+\.rb): (?<seconds>\d+(?:\.\d+)?)$}

def api_headers
  return { 'JOB-TOKEN' => ENV['CI_JOB_TOKEN'] } if ENV['CI_JOB_TOKEN'].to_s != ''
  return { 'PRIVATE-TOKEN' => ENV['GITLAB_TOKEN'] } if ENV['GITLAB_TOKEN'].to_s != ''

  abort 'ERROR: neither GITLAB_TOKEN nor CI_JOB_TOKEN is set.'
end

def api_get(path)
  response = Net::HTTP.get_response(URI("#{API_URL}/#{path}"), api_headers)

  response.is_a?(Net::HTTPSuccess) ? response.body : nil
end

def pipeline_jobs(pipeline_id)
  jobs = []
  page = 1

  loop do
    body = api_get("projects/#{PROJECT}/pipelines/#{pipeline_id}/jobs?per_page=100&page=#{page}")
    abort "ERROR: could not fetch the jobs of pipeline #{pipeline_id}." if body.nil?

    batch = JSON.parse(body)
    break if batch.empty?

    jobs += batch
    page += 1
  end

  jobs
end

def job_timings(job)
  timings = {}

  trace = api_get("projects/#{PROJECT}/jobs/#{job['id']}/artifacts/trace") || api_get("projects/#{PROJECT}/jobs/#{job['id']}/trace")
  if trace.nil?
    puts "  #{job['name']}: no job log available, skipping"
    return timings
  end

  trace.each_line do |line|
    match = TIMING_LINE.match(clean_log_line(line))
    next if match.nil?

    timings[match[:file]] = match[:seconds].to_f
  end

  puts "  #{job['name']}: #{timings.size} files"

  timings
end

# Strip the timestamp prefix and the color codes which GitLab adds to each log line.
def clean_log_line(line)
  line
    .gsub(%r{\e\[[0-9;]*[a-zA-Z]}, '')
    .sub(%r{^\d{4}-\d{2}-\d{2}T[\d:.]+Z \d{2}[A-Z]\+?K? ?}, '')
    .strip
end

def write_timings_file(file, timings)
  if timings.empty?
    puts "No timings found for #{file}, keeping it unchanged."
    return
  end

  # Keep the runtimes of files which were not measured in this pipeline, e.g. because their
  #   jobs did not run. Only keep files which still exist, so that the data does not pile up.
  timings = YAML.load_file(file).merge(timings) if File.exist?(file)
  timings = timings.select { |path, _seconds| File.exist?(path) }

  header  = File.exist?(file) ? File.readlines(file).take_while { |line| line.start_with?('#', '---') } : []
  content = header.join + timings.sort.map { |path, seconds| "#{path}: #{[seconds.round(1), 0.1].max}\n" }.join

  File.write(file, content)

  puts "#{file}: #{timings.size} files, #{(timings.values.sum / 60).round(1)} minutes in total"
end

pipeline_id = ARGV[0]
abort 'Usage: script/build/update_test_timings.rb <pipeline-id>' if pipeline_id.to_s.empty?

jobs = pipeline_jobs(pipeline_id)

TIMINGS_FILES.each do |file, job_pattern|
  timings = {}

  jobs.select { |job| job['name'].match?(job_pattern) }.each do |job|
    job_timings(job).each do |path, seconds|
      # A file may run in more than one job, use the longest runtime in that case.
      timings[path] = [timings[path] || 0, seconds].max
    end
  end

  write_timings_file(file, timings)
end

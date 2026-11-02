#!/usr/bin/env ruby
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Refreshes the test timings in .gitlab/ci/timings/ from CI pipelines, which are used to
#   distribute the test files evenly over the parallel CI jobs.
#
# Usage: GITLAB_TOKEN=… script/build/update_test_timings.rb <pipeline-id> [<pipeline-id> …]
#
# Use pipelines which ran the complete test suite, otherwise the missing files fall back
#   to an estimation based on their file size.
#
# The runtime of a spec file differs a lot between runners, so pass several pipelines,
#   e.g. five: each file gets the median of its runtimes in them.
#
# The runtimes are read from the job logs (see .gitlab/print_test_timings.sh) instead of
#   job artifacts, to avoid uploading artifacts of successful jobs just for this purpose.

require 'json'
require 'net/http'
require 'uri'
require 'yaml'

class UpdateTestTimings
  API_URL = ENV.fetch('CI_API_V4_URL', 'https://git.zammad.com/api/v4')
  PROJECT = ENV.fetch('CI_PROJECT_ID', 'zammad%2Fzammad')

  # Which jobs provide the runtimes of which timings file.
  TIMINGS_FILES = {
    '.gitlab/ci/timings/rspec.yml' => %r{^(rspec|capybara:chromium) \d+/\d+$},
  }.freeze

  # Lines of the recorded timings YAML in the job log, e.g. 'spec/models/user_spec.rb: 12.3'.
  TIMING_LINE = %r{^(?<file>spec/\S+\.rb): (?<seconds>\d+(?:\.\d+)?)$}

  attr_reader :pipeline_ids

  def self.median(values)
    sorted = values.sort
    middle = sorted.size / 2

    sorted.size.odd? ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2
  end

  def initialize(pipeline_ids)
    @pipeline_ids = pipeline_ids
  end

  def run
    TIMINGS_FILES.each do |file, job_pattern|
      write_timings_file(file, median_timings(job_pattern))
    end
  end

  # The median runtime of each spec file over all pipelines which measured it.
  def median_timings(job_pattern)
    runtimes = Hash.new { |hash, path| hash[path] = [] }

    jobs_per_pipeline.each do |pipeline_id, jobs|
      puts "Pipeline #{pipeline_id}:"
      pipeline_timings(jobs, job_pattern).each { |path, seconds| runtimes[path] << seconds }
    end

    runtimes.transform_values { |values| self.class.median(values) }
  end

  private

  def jobs_per_pipeline
    @jobs_per_pipeline ||= pipeline_ids.map { |pipeline_id| [pipeline_id, pipeline_jobs(pipeline_id)] }
  end

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

  def pipeline_timings(jobs, job_pattern)
    timings = {}

    jobs.select { |job| job['name'].match?(job_pattern) }.each do |job|
      job_timings(job).each do |path, seconds|
        # A file may run in more than one job, use the longest runtime in that case.
        timings[path] = [timings[path] || 0, seconds].max
      end
    end

    timings
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

    # Keep the runtimes of files which were not measured in these pipelines, e.g. because their
    #   jobs did not run. Only keep files which still exist, so that the data does not pile up.
    timings = YAML.load_file(file).merge(timings) if File.exist?(file)
    timings = timings.select { |path, _seconds| File.exist?(path) }

    header  = File.exist?(file) ? File.readlines(file).take_while { |line| line.start_with?('#', '---') } : []
    content = header.join + timings.sort.map { |path, seconds| "#{path}: #{[seconds.round(1), 0.1].max}\n" }.join

    File.write(file, content)

    puts "#{file}: #{timings.size} files, #{(timings.values.sum / 60).round(1)} minutes in total"
  end
end

if $PROGRAM_NAME == __FILE__
  abort 'Usage: script/build/update_test_timings.rb <pipeline-id> [<pipeline-id> …]' if ARGV.empty?

  UpdateTestTimings.new(ARGV).run
end

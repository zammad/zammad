# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'puma'

module PlaywrightNative
  # Serves the app from this process, so the server shares the example's database
  #   connection and sees its uncommitted records.
  module AppServer
    # Counts the requests in progress, so an example ends only once the server is done with
    #   it, and keeps the first error of the app for the example.
    class Middleware
      attr_reader :error

      def initialize(app)
        @app      = app
        @requests = Concurrent::AtomicFixnum.new
      end

      def call(env)
        @requests.increment
        @app.call(env)
      rescue => e
        @error ||= e
        raise
      ensure
        @requests.decrement
      end

      def idle?
        @requests.value.zero?
      end

      def take_error
        error.tap { @error = nil }
      end
    end

    def self.url
      "https://#{PLAYWRIGHT_APP_HOSTNAME}:#{PLAYWRIGHT_APP_PORT}"
    end

    def self.start
      return if @middleware

      authority = Localhost::Authority.new(PLAYWRIGHT_APP_HOSTNAME, issuer: nil)
      authority.save

      @middleware = Middleware.new(Rails.application)

      @server = Puma::Server.new(@middleware, nil, min_threads: 0, max_threads: 16, log_writer: Puma::LogWriter.null)
      @server.binder.parse(["ssl://0.0.0.0:#{PLAYWRIGHT_APP_PORT}?key=#{authority.key_path}&cert=#{authority.certificate_path}"])
      @server.run
    end

    def self.finish_example
      # Firefox may keep the websocket of a closed context open, its connection would never end.
      ActionCable.server.connections.dup.each(&:close)
      wait_until_idle

      error = @middleware.take_error
      raise error if error
    end

    # Its threads share the example's database connection, so work left over from the closed
    #   browser - a queued request, the websocket's close - deadlocks with the next example.
    def self.wait_until_idle
      Timeout.timeout(PLAYWRIGHT_TIMEOUT) { sleep 0.01 while busy.any? }
    rescue Timeout::Error
      raise "The app server is still busy after the example: #{busy.join(', ')}"
    end

    def self.busy
      cable_workers = ActionCable.server.worker_pool.executor

      {
        'requests'          => !@middleware.idle?,
        'queued requests'   => @server.stats[:busy_threads].positive?,
        'cable connections' => ActionCable.server.connections.any?,
        'cable work'        => cable_workers.active_count.positive? || cable_workers.queue_length.positive?,
      }.select { |_name, busy| busy }.keys
    end
  end
end

RSpec.configure do |config|
  config.before(:each, type: :playwright) do
    PlaywrightNative::AppServer.start

    Setting.set('http_type', 'https')
    Setting.set('fqdn', "#{PLAYWRIGHT_APP_HOSTNAME}:#{PLAYWRIGHT_APP_PORT}")
  end

  config.around(:each, type: :playwright) do |example|
    use_vcr = example.metadata.fetch(:use_vcr, false)

    # Like the system specs: the app may reach out for real, unless the example records with VCR.
    WebMock.disable! if !use_vcr
    example.run
  ensure
    WebMock.enable! if !use_vcr
  end
end

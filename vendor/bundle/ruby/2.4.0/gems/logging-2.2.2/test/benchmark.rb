require 'rubygems'

libpath = File.expand_path('../../lib', __FILE__)
$:.unshift libpath
require 'logging'

begin
  gem 'log4r'
  require 'log4r'
  $log4r = true
rescue LoadError
  $log4r = false
end

require 'benchmark'
require 'logger'

module Logging
  class Benchmark

    def run
      this_many = 300_000

      pattern = Logging.layouts.pattern \
        :pattern      => '%.1l, [%d #%p] %5l -- %c: %m\n',
        :date_pattern => "%Y-%m-%dT%H:%M:%S.%s"

      Logging.appenders.string_io('sio', :layout => pattern)
      sio = Logging.appenders['sio'].sio

      logging = ::Logging.logger['benchmark']
      logging.level = :warn
      logging.appenders = 'sio'

      logger = ::Logger.new sio
      logger.level = ::Logger::WARN

      log4r = if $log4r
        l4r = ::Log4r::Logger.new('benchmark')
        l4r.level = ::Log4r::WARN
        l4r.add ::Log4r::IOOutputter.new(
          'benchmark', sio,
          :formatter => ::Log4r::PatternFormatter.new(
            :pattern => "%.1l, [%d #\#{Process.pid}] %5l : %M\n",
            :date_pattern => "%Y-%m-%dT%H:%M:%S.%6N"
          )
        )
        l4r
      end

      puts "== Debug (not logged) ==\n"
      ::Benchmark.bm(10) do |bm|
        bm.report('Logging:') {this_many.times {logging.debug 'not logged'}}
        bm.report('Logger:') {this_many.times {logger.debug 'not logged'}}
        bm.report('Log4r:') {this_many.times {log4r.debug 'not logged'}} if log4r
      end

      puts "\n== Warn (logged) ==\n"
      ::Benchmark.bm(10) do |bm|
        sio.seek 0
        bm.report('Logging:') {this_many.times {logging.warn 'logged'}}
        sio.seek 0
        bm.report('Logger:') {this_many.times {logger.warn 'logged'}}
        sio.seek 0
        bm.report('Log4r:') {this_many.times {log4r.warn 'logged'}} if log4r
      end

      puts "\n== Concat ==\n"
      ::Benchmark.bm(10) do |bm|
        sio.seek 0
        bm.report('Logging:') {this_many.times {logging << 'logged'}}
        sio.seek 0
        bm.report('Logger:') {this_many.times {logger << 'logged'}}
        puts "Log4r:      not supported" if log4r
      end

      write_size         = 250
      auto_flushing_size = 500

      logging_async = ::Logging.logger['AsyncFile']
      logging_async.level = :info
      logging_async.appenders = Logging.appenders.file \
          'benchmark_async.log',
          :layout => pattern,
          :write_size => write_size,
          :auto_flushing => auto_flushing_size,
          :async => true

      logging_sync = ::Logging.logger['SyncFile']
      logging_sync.level = :info
      logging_sync.appenders = Logging.appenders.file \
          'benchmark_sync.log',
          :layout => pattern,
          :write_size => write_size,
          :auto_flushing => auto_flushing_size,
          :async => false

      puts "\n== File ==\n"
      ::Benchmark.bm(20) do |bm|
        bm.report('Logging (Async):') {this_many.times { |n| logging_async.info "Iteration #{n}"}}
        bm.report('Logging (Sync):')  {this_many.times { |n| logging_sync.info  "Iteration #{n}"}}
      end

      File.delete('benchmark_async.log')
      File.delete('benchmark_sync.log')
    end
  end
end

if __FILE__ == $0
  bm = ::Logging::Benchmark.new
  bm.run
end

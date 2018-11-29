#
# The peformance script is used to output a performance analysis page for the
# Logging framework. You can run this script simply:
#
#   ruby test/performance.rb
#
# This will write a file called "performance.html" that you can open in your web
# browser. You will need the `ruby-prof` gem installed in order to run this
# script.
# ------------------------------------------------------------------------------
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

require 'logger'
require 'ruby-prof'

module Logging
  class Performance

    # number of iterations
    attr_reader :this_many

    # performance output file name
    attr_reader :output_file

    def initialize
      @this_many   = 300_000
      @output_file = "performance.html"
    end

    def run
      pattern = Logging.layouts.pattern \
        :pattern      => '%.1l, [%d#%p] %5l -- %c: %m\n',
        :date_pattern => "%Y-%m-%dT%H:%M:%S.%s"

      Logging.appenders.string_io("sio", :layout => pattern)

      logger = ::Logging.logger["Performance"]
      logger.level = :warn
      logger.appenders = "sio"

      result = RubyProf.profile do
        this_many.times {logger.warn 'logged'}
      end

      printer = RubyProf::GraphHtmlPrinter.new(result)
      File.open(output_file, "w") { |fd| printer.print(fd) }
    end
  end
end

if __FILE__ == $0
  perf = Logging::Performance.new
  perf.run
end

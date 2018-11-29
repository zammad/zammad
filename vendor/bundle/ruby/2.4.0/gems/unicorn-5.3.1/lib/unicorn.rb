# -*- encoding: binary -*-
require 'etc'
require 'stringio'
require 'kgio'

begin
  require 'rack'
rescue LoadError
  warn 'rack not available, functionality reduced'
end

# :stopdoc:
# Unicorn module containing all of the classes (include C extensions) for
# running a Unicorn web server.  It contains a minimalist HTTP server with just
# enough functionality to service web application requests fast as possible.
# :startdoc:

# unicorn exposes very little of an user-visible API and most of its
# internals are subject to change.  unicorn is designed to host Rack
# applications, so applications should be written against the Rack SPEC
# and not unicorn internals.
module Unicorn

  # Raised inside TeeInput when a client closes the socket inside the
  # application dispatch.  This is always raised with an empty backtrace
  # since there is nothing in the application stack that is responsible
  # for client shutdowns/disconnects.  This exception is visible to Rack
  # applications unless PrereadInput middleware is loaded.  This
  # is a subclass of the standard EOFError class and applications should
  # not rescue it explicitly, but rescue EOFError instead.
  ClientShutdown = Class.new(EOFError)

  # :stopdoc:

  # This returns a lambda to pass in as the app, this does not "build" the
  # app (which we defer based on the outcome of "preload_app" in the
  # Unicorn config).  The returned lambda will be called when it is
  # time to build the app.
  def self.builder(ru, op)
    # allow Configurator to parse cli switches embedded in the ru file
    op = Unicorn::Configurator::RACKUP.merge!(:file => ru, :optparse => op)
    if ru =~ /\.ru$/ && !defined?(Rack::Builder)
      abort "rack and Rack::Builder must be available for processing #{ru}"
    end

    # Op is going to get cleared before the returned lambda is called, so
    # save this value so that it's still there when we need it:
    no_default_middleware = op[:no_default_middleware]

    # always called after config file parsing, may be called after forking
    lambda do ||
      inner_app = case ru
      when /\.ru$/
        raw = File.read(ru)
        raw.sub!(/^__END__\n.*/, '')
        eval("Rack::Builder.new {(\n#{raw}\n)}.to_app", TOPLEVEL_BINDING, ru)
      else
        require ru
        Object.const_get(File.basename(ru, '.rb').capitalize)
      end

      pp({ :inner_app => inner_app }) if $DEBUG

      return inner_app if no_default_middleware

      middleware = { # order matters
        ContentLength: nil,
        Chunked: nil,
        CommonLogger: [ $stderr ],
        ShowExceptions: nil,
        Lint: nil,
        TempfileReaper: nil,
      }

      # return value, matches rackup defaults based on env
      # Unicorn does not support persistent connections, but Rainbows!
      # and Zbatery both do.  Users accustomed to the Rack::Server default
      # middlewares will need ContentLength/Chunked middlewares.
      case ENV["RACK_ENV"]
      when "development"
      when "deployment"
        middleware.delete(:ShowExceptions)
        middleware.delete(:Lint)
      else
        return inner_app
      end
      Rack::Builder.new do
        middleware.each do |m, args|
          use(Rack.const_get(m), *args) if Rack.const_defined?(m)
        end
        run inner_app
      end.to_app
    end
  end

  # returns an array of strings representing TCP listen socket addresses
  # and Unix domain socket paths.  This is useful for use with
  # Raindrops::Middleware under Linux: https://bogomips.org/raindrops/
  def self.listener_names
    Unicorn::HttpServer::LISTENERS.map do |io|
      Unicorn::SocketHelper.sock_name(io)
    end + Unicorn::HttpServer::NEW_LISTENERS
  end

  def self.log_error(logger, prefix, exc)
    message = exc.message
    message = message.dump if /[[:cntrl:]]/ =~ message
    logger.error "#{prefix}: #{message} (#{exc.class})"
    exc.backtrace.each { |line| logger.error(line) }
  end

  # remove this when we only support Ruby >= 2.0
  def self.pipe # :nodoc:
    Kgio::Pipe.new.each { |io| io.close_on_exec = true }
  end
  # :startdoc:
end
# :enddoc:

%w(const socket_helper stream_input tee_input http_request configurator
   tmpio util http_response worker http_server).each do |s|
  require_relative "unicorn/#{s}"
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

begin
  require 'execjs'
rescue LoadError
  # The assets group of the Gemfile is not installed.
  return
end

require 'securerandom'

module ExecJS
  # A runtime like ExecJS::Runtimes::Node, but it keeps a single long-lived
  #   node process instead of spawning a new one for every single call.
  #   Compiling all CoffeeScript/Eco assets this way is much faster, without
  #   requiring a native V8 gem like mini_racer which cannot be built on all
  #   supported platforms.
  class PersistentNodeRuntime < Runtime
    RUNNER_SOURCE = <<~'JAVASCRIPT'.freeze
      'use strict';
      const vm = require('vm');
      const contexts = new Map();
      let buffer = '';

      function perform(request) {
        if (request.method === 'create') {
          const context = vm.createContext({});
          if (request.source.length) {
            vm.runInContext(request.source, context, { filename: '(execjs)' });
          }
          contexts.set(request.context, context);
          return undefined;
        }

        const context = contexts.get(request.context);
        if (!context) {
          throw new Error('EXECJS_CONTEXT_MISSING');
        }

        return vm.runInContext(request.source, context, { filename: '(execjs)' });
      }

      function respond(line) {
        let response;
        try {
          const result = perform(JSON.parse(line));
          if (typeof result === 'undefined' || typeof result === 'function') {
            response = JSON.stringify(['ok']);
          } else {
            response = JSON.stringify(['ok', result]);
          }
        } catch (error) {
          response = JSON.stringify(['err', String(error), String((error && error.stack) || '')]);
        }
        process.stdout.write(response + '\n');
      }

      process.stdin.setEncoding('utf8');
      process.stdin.on('data', (chunk) => {
        buffer += chunk;
        let index;
        while ((index = buffer.indexOf('\n')) >= 0) {
          const line = buffer.slice(0, index);
          buffer = buffer.slice(index + 1);
          if (line.length) respond(line);
        }
      });
      process.stdin.on('end', () => process.exit(0));
    JAVASCRIPT

    class Context < Runtime::Context
      def initialize(runtime, source = '', _options = {})
        super

        @runtime = runtime
        @id      = SecureRandom.uuid
        @source  = source.encode(Encoding::UTF_8)

        create
      end

      def exec(source, _options = {})
        source = source.encode(Encoding::UTF_8)

        return if !%r{\S}.match?(source)

        raw_eval("(function(){#{source}})()")
      end

      def eval(source, _options = {})
        source = source.encode(Encoding::UTF_8)

        return if !%r{\S}.match?(source)

        raw_eval("(#{source})")
      end

      def call(identifier, *args)
        raw_eval("(#{identifier}).apply(this, #{::JSON.generate(args)})")
      end

      private

      def create
        @runtime.command(method: 'create', context: @id, source: @source)
      end

      # The node process may have been replaced after a crash or a fork,
      #   in which case the context needs to be created again.
      def raw_eval(source, may_retry: true)
        @runtime.command(method: 'eval', context: @id, source: source)
      rescue ProgramError => e
        raise if !may_retry || e.message.exclude?('EXECJS_CONTEXT_MISSING')

        create
        raw_eval(source, may_retry: false)
      end
    end

    def initialize
      super

      @mutex      = Mutex.new
      @process_io = nil
      @pid        = nil
    end

    def name
      __('Persistent Node.js (V8)')
    end

    def available?
      !binary.nil?
    end

    def command(payload)
      @mutex.synchronize do
        io = process_io

        begin
          io.puts(::JSON.generate(payload))
          response = io.gets
        rescue Errno::EPIPE
          response = nil
        end

        if response.nil?
          @process_io = nil # spawn a fresh process on the next command
          raise ExecJS::RuntimeError, __('The persistent node process died unexpectedly.')
        end

        status, value, stack = ::JSON.parse(response)

        return value if status == 'ok'

        raise js_error(value.to_s, stack.to_s)
      end
    end

    private

    def js_error(message, stack)
      error_class = message.include?('SyntaxError') ? RuntimeError : ProgramError
      error       = error_class.new(message)
      error.set_backtrace(stack.split("\n").map(&:strip) + caller)
      error
    end

    def process_io
      @process_io = nil if @pid != Process.pid # after a fork, the process belongs to the parent

      @process_io ||= begin
        @pid = Process.pid
        IO.popen([binary, '-e', RUNNER_SOURCE], 'r+', external_encoding: 'UTF-8', internal_encoding: 'UTF-8')
      end
    end

    def binary
      return @binary if defined?(@binary)

      @binary = %w[node nodejs].find do |command|
        ENV['PATH'].to_s.split(File::PATH_SEPARATOR).any? do |dir|
          candidate = File.join(dir, command)
          File.file?(candidate) && File.executable?(candidate)
        end
      end
    end
  end
end

module Mysql2
  class Client
    attr_reader :query_options, :read_timeout

    def self.default_query_options
      @default_query_options ||= {
        :as => :hash,                   # the type of object you want each row back as; also supports :array (an array of values)
        :async => false,                # don't wait for a result after sending the query, you'll have to monitor the socket yourself then eventually call Mysql2::Client#async_result
        :cast_booleans => false,        # cast tinyint(1) fields as true/false in ruby
        :symbolize_keys => false,       # return field names as symbols instead of strings
        :database_timezone => :local,   # timezone Mysql2 will assume datetime objects are stored in
        :application_timezone => nil,   # timezone Mysql2 will convert to before handing the object back to the caller
        :cache_rows => true,            # tells Mysql2 to use its internal row cache for results
        :connect_flags => REMEMBER_OPTIONS | LONG_PASSWORD | LONG_FLAG | TRANSACTIONS | PROTOCOL_41 | SECURE_CONNECTION,
        :cast => true,
        :default_file => nil,
        :default_group => nil,
      }
    end

    def initialize(opts = {})
      fail Mysql2::Error, "Options parameter must be a Hash" unless opts.is_a? Hash
      opts = Mysql2::Util.key_hash_as_symbols(opts)
      @read_timeout = nil
      @query_options = self.class.default_query_options.dup
      @query_options.merge! opts

      initialize_ext

      # Set default connect_timeout to avoid unlimited retries from signal interruption
      opts[:connect_timeout] = 120 unless opts.key?(:connect_timeout)

      # TODO: stricter validation rather than silent massaging
      [:reconnect, :connect_timeout, :local_infile, :read_timeout, :write_timeout, :default_file, :default_group, :secure_auth, :init_command, :automatic_close, :enable_cleartext_plugin].each do |key|
        next unless opts.key?(key)
        case key
        when :reconnect, :local_infile, :secure_auth, :automatic_close, :enable_cleartext_plugin
          send(:"#{key}=", !!opts[key]) # rubocop:disable Style/DoubleNegation
        when :connect_timeout, :read_timeout, :write_timeout
          send(:"#{key}=", Integer(opts[key])) unless opts[key].nil?
        else
          send(:"#{key}=", opts[key])
        end
      end

      # force the encoding to utf8
      self.charset_name = opts[:encoding] || 'utf8'

      ssl_options = opts.values_at(:sslkey, :sslcert, :sslca, :sslcapath, :sslcipher)
      ssl_set(*ssl_options) if ssl_options.any? || opts.key?(:sslverify)
      self.ssl_mode = parse_ssl_mode(opts[:ssl_mode]) if opts[:ssl_mode]

      case opts[:flags]
      when Array
        flags = parse_flags_array(opts[:flags], @query_options[:connect_flags])
      when String
        flags = parse_flags_array(opts[:flags].split(' '), @query_options[:connect_flags])
      when Integer
        flags = @query_options[:connect_flags] | opts[:flags]
      else
        flags = @query_options[:connect_flags]
      end

      # SSL verify is a connection flag rather than a mysql_ssl_set option
      flags |= SSL_VERIFY_SERVER_CERT if opts[:sslverify]

      if [:user, :pass, :hostname, :dbname, :db, :sock].any? { |k| @query_options.key?(k) }
        warn "============= WARNING FROM mysql2 ============="
        warn "The options :user, :pass, :hostname, :dbname, :db, and :sock are deprecated and will be removed at some point in the future."
        warn "Instead, please use :username, :password, :host, :port, :database, :socket, :flags for the options."
        warn "============= END WARNING FROM mysql2 ========="
      end

      user     = opts[:username] || opts[:user]
      pass     = opts[:password] || opts[:pass]
      host     = opts[:host] || opts[:hostname]
      port     = opts[:port]
      database = opts[:database] || opts[:dbname] || opts[:db]
      socket   = opts[:socket] || opts[:sock]

      # Correct the data types before passing these values down to the C level
      user = user.to_s unless user.nil?
      pass = pass.to_s unless pass.nil?
      host = host.to_s unless host.nil?
      port = port.to_i unless port.nil?
      database = database.to_s unless database.nil?
      socket = socket.to_s unless socket.nil?

      connect user, pass, host, port, database, socket, flags
    end

    def parse_ssl_mode(mode)
      m = mode.to_s.upcase
      if m.start_with?('SSL_MODE_')
        return Mysql2::Client.const_get(m) if Mysql2::Client.const_defined?(m)
      else
        x = 'SSL_MODE_' + m
        return Mysql2::Client.const_get(x) if Mysql2::Client.const_defined?(x)
      end
      warn "Unknown MySQL ssl_mode flag: #{mode}"
    end

    def parse_flags_array(flags, initial = 0)
      flags.reduce(initial) do |memo, f|
        fneg = f.start_with?('-') ? f[1..-1] : nil
        if fneg && fneg =~ /^\w+$/ && Mysql2::Client.const_defined?(fneg)
          memo & ~ Mysql2::Client.const_get(fneg)
        elsif f && f =~ /^\w+$/ && Mysql2::Client.const_defined?(f)
          memo | Mysql2::Client.const_get(f)
        else
          warn "Unknown MySQL connection flag: '#{f}'"
          memo
        end
      end
    end

    if Thread.respond_to?(:handle_interrupt)
      def query(sql, options = {})
        Thread.handle_interrupt(::Mysql2::Util::TimeoutError => :never) do
          _query(sql, @query_options.merge(options))
        end
      end
    else
      def query(sql, options = {})
        _query(sql, @query_options.merge(options))
      end
    end

    def query_info
      info = query_info_string
      return {} unless info
      info_hash = {}
      info.split.each_slice(2) { |s| info_hash[s[0].downcase.delete(':').to_sym] = s[1].to_i }
      info_hash
    end

    def info
      self.class.info
    end

    class << self
      private

      def local_offset
        ::Time.local(2010).utc_offset.to_r / 86400
      end
    end
  end
end

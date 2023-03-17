# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Exchange::Connection < Sequencer::Unit::Common::Provider::Fallback

  uses :ews_config
  provides :ews_connection

  private

  def ews_connection
    load_viewpoint_class

    Viewpoint::EWSClient.new({
                               endpoint: config[:endpoint],
                               type:     config[:auth_type],
                               token:    config[:access_token],
                               user:     config[:user],
                               password: config[:password]
                             }, additional_opts)
  end

  def config
    @config ||= begin
      config = ews_config
      if !ews_config
        config = ::Import::Exchange.config
        if config[:auth_type] == 'oauth'
          config = config.merge(Setting.get('exchange_oauth'))
        end
      end
      config
    end
  end

  def additional_opts
    @additional_opts ||= begin
      http_opts
    end
  end

  def http_opts
    return {} if config[:disable_ssl_verify].blank?

    {
      http_opts: {
        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
      }
    }
  end

  def load_viewpoint_class
    return if defined?(Viewpoint::EWS::Connection)

    require 'viewpoint'

    Viewpoint::EWS::Connection.class_eval do
      # ---
      # Zammad
      # ---
      # def initialize(endpoint, opts = {})
      #   @log = Logging.logger[self.class.name.to_s.to_sym]
      #   if opts[:user_agent]
      #     @httpcli = HTTPClient.new(agent_name: opts[:user_agent])
      #   else
      #     @httpcli = HTTPClient.new
      #   end
      #
      #   if opts[:trust_ca]
      #     @httpcli.ssl_config.clear_cert_store
      #     opts[:trust_ca].each do |ca|
      #       @httpcli.ssl_config.add_trust_ca ca
      #     end
      #   end
      #
      #   @httpcli.ssl_config.verify_mode = opts[:ssl_verify_mode] if opts[:ssl_verify_mode]
      #   @httpcli.ssl_config.ssl_version = opts[:ssl_version] if opts[:ssl_version]
      #   # Up the keep-alive so we don't have to do the NTLM dance as often.
      #   @httpcli.keep_alive_timeout = 60
      #   @httpcli.receive_timeout = opts[:receive_timeout] if opts[:receive_timeout]
      #   @httpcli.connect_timeout = opts[:connect_timeout] if opts[:connect_timeout]
      #   @endpoint = endpoint
      # end

      def initialize(auth, opts = {})
        @log = Logging.logger[self.class.name.to_s.to_sym]

        @httpcli = http_object(opts)

        @auth_type  = auth[:type]
        @auth_token = @auth_type == 'oauth' ? auth[:token] : nil

        @endpoint = auth[:endpoint]
      end
      # ---

      def post(xmldoc)
        headers = { 'Content-Type' => 'text/xml' }
        # ---
        # Zammad
        # ---
        if @auth_type == 'oauth' && @auth_token.present?
          headers = headers.merge({ 'Authorization' => "Bearer #{@auth_token}" })
        end

        # ---
        check_response(@httpcli.post(@endpoint, xmldoc, headers))
      end

      # ---
      # Zammad
      # ---
      private

      def http_object(opts)
        @httpcli = if opts[:user_agent]
                     HTTPClient.new(agent_name: opts[:user_agent])
                   else
                     HTTPClient.new
                   end

        trust_ca_option(opts)
        ssl_config(opts)
        timeout_options(opts)

        @httpcli
      end

      def trust_ca_option(opts)
        return if opts[:trust_ca].nil?

        @httpcli.ssl_config.clear_cert_store
        opts[:trust_ca].each do |ca|
          @httpcli.ssl_config.add_trust_ca ca
        end
      end

      def ssl_config(opts)
        @httpcli.ssl_config.verify_mode = opts[:ssl_verify_mode] if opts[:ssl_verify_mode]
        @httpcli.ssl_config.ssl_version = opts[:ssl_version] if opts[:ssl_version]
      end

      def timeout_options(opts)
        # Up the keep-alive so we don't have to do the NTLM dance as often.
        @httpcli.keep_alive_timeout = 60
        @httpcli.receive_timeout = opts[:receive_timeout] if opts[:receive_timeout]
        @httpcli.connect_timeout = opts[:connect_timeout] if opts[:connect_timeout]
      end
      # ---
    end

    Viewpoint::EWSClient.class_eval do
      # ---
      # Zammad
      # ---
      # def initialize(endpoint, username, password, opts = {})
      #   # dup all. @see ticket https://github.com/zenchild/Viewpoint/issues/68
      #   @endpoint = endpoint.dup
      #   @username = username.dup
      #   password  = password.dup
      #   opts      = opts.dup
      #   http_klass = opts[:http_class] || Viewpoint::EWS::Connection
      #   con = http_klass.new(endpoint, opts[:http_opts] || {})
      #   con.set_auth @username, password
      #   @ews = SOAP::ExchangeWebService.new(con, opts)
      # end
      def initialize(auth, opts = {})
        auth = auth.dup

        @auth_type  = auth[:type]
        @auth_token = @auth_type == 'oauth' ? auth[:token] : nil

        @endpoint   = auth[:endpoint]
        @username   = auth[:user]
        password    = @auth_type == 'basic' ? auth[:password] : nil

        http_klass = opts[:http_class] || Viewpoint::EWS::Connection
        connection = http_klass.new(auth, opts[:http_opts] || {})
        connection.set_auth(@username, password) if password.present?

        @ews = Viewpoint::EWS::SOAP::ExchangeWebService.new(connection, opts)
      end
      # ---
    end
  end
end

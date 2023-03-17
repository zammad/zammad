# rubocop:disable all
module Net
  class SMTP

    def do_start(helo_domain, user, secret, authtype)
      raise IOError, 'SMTP session already started' if @started
      if user or secret
        check_auth_method(authtype || DEFAULT_AUTH_TYPE)
        check_auth_args user, secret
      end
      s = Timeout.timeout(@open_timeout, Net::OpenTimeout) do
        tcp_socket(@address, @port)
      end
      logging "Connection opened: #{@address}:#{@port}"
      @socket = new_internet_message_io(tls? ? tlsconnect(s, @ssl_context_tls) : s)
      check_response critical { recv_response() }
      do_helo helo_domain
      if ! tls? and (starttls_always? or (capable_starttls? and starttls_auto?))
        unless capable_starttls?
          raise SMTPUnsupportedCommand,
              "STARTTLS is not supported on this server"
        end
        starttls
        @socket = new_internet_message_io(tlsconnect(s, @ssl_context_starttls))
        # helo response may be different after STARTTLS
        do_helo helo_domain
      end

      #
      # ADD auto detection of authtype - https://github.com/zammad/zammad/issues/240
      #
      # set detected authtype based on smtp server capabilities
      if user or secret
        if !authtype
          if auth_capable?(DEFAULT_AUTH_TYPE)
            authtype = DEFAULT_AUTH_TYPE
          elsif capable_cram_md5_auth?
            authtype = :cram_md5
          elsif capable_login_auth?
            authtype = :login
          elsif capable_plain_auth?
            authtype = :plain
          end
        end
      end
      #
      # /ADD auto detection of authtype - https://github.com/zammad/zammad/issues/240
      #

      authenticate user, secret, (authtype || DEFAULT_AUTH_TYPE) if user
      @started = true
    ensure
      unless @started
        # authentication failed, cancel connection.
        s.close if s
        @socket = nil
      end
    end
  end
end
# rubocop:enable all

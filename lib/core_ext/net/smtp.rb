# rubocop:disable all
module Net
  class SMTP
    #
    # ADD mark for an error of the session setup (greeting, EHLO, STARTTLS, login),
    # which tells it from a reply to a mail
    #
    module SessionSetupError; end
    #
    # /ADD mark for an error of the session setup
    #

    def do_start(helo_domain, user, secret, authtype)
      raise IOError, 'SMTP session already started' if @started
      if user || secret || authtype
        check_auth_args authtype, user, secret
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
          raise SMTPUnsupportedCommand, "STARTTLS is not supported on this server"
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
    #
    # ADD mark for an error of the session setup
    #
    rescue SMTPError => e
      e.extend(SessionSetupError)
      raise
    #
    # /ADD mark for an error of the session setup
    #
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

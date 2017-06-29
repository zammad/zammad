# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Channel::Driver::Smtp < Channel::EmailParser

=begin

  instance = Channel::Driver::Smtp.new
  instance.send(
    {
      host:                 'some.host',
      port:                 25,
      enable_starttls_auto: true, # optional
      openssl_verify_mode:  'none', # optional
      user:                 'someuser',
      password:             'somepass'
      authentication:       nil, # nil, autodetection - to use certain schema use 'plain', 'login' or 'cram_md5'
    },
    mail_attributes,
    notification
  )

=end

  class SmtpListener < MidiSmtpServer::Smtpd
    attr_reader :port

    def initialize(port, driver_instance)
      super(port, '0.0.0.0', 4, { auth_mode: :AUTH_FORBIDDEN })
      @driver_instance = driver_instance
    end

    def start
      Rails.logger.debug "Starting smtp server listening on port #{@port}"
      super
    end

    def on_message_data_event(ctx)
      @driver_instance.message_received(ctx[:message][:data], @port)
    end
  end

  def listen(channel)
    @channel = channel
    port = @channel.options[:inbound][:options][:port].to_i

    shutdown
    raise "Cannot listen on port #{port}. Port is invalid." unless (1..65_535).cover?(port)
    @server = SmtpListener.new(port, self)
    @server.start
  end

  def shutdown
    return if @server.nil? || @server.stopped?

    # Attempt to allow connections to close gracefully
    @server.shutdown
    sleep 2 unless @server.connections.zero?

    Rails.logger.debug "Stopping smtp server listening on port #{@server.port}"
    # stop all threads and connections
    @server.stop

    logger.debug
  end

  def fetchable?(_channel)
    false
  end

  def message_received(message, port)
    Rails.logger.debug "Processing message for channel with id #{@channel.id} received on port #{port}"
    process(@channel, message, false)
  end

  def send(options, attr, notification = false)

    # return if we run import mode
    return if Setting.get('import_mode')

    # set smtp defaults
    if !options.key?(:port) || options[:port].empty?
      options[:port] = 25
    end
    if !options.key?(:ssl)
      if options[:port].to_i == 465
        options[:ssl] = true
      end
    end
    if !options.key?(:domain)
      # set fqdn, if local fqdn - use domain of sender
      fqdn = Setting.get('fqdn')
      if fqdn =~ /(localhost|\.local^|\.loc^)/i && (attr['from'] || attr[:from])
        domain = Mail::Address.new(attr['from'] || attr[:from]).domain
        if domain
          fqdn = domain
        end
      end
      options[:domain] = fqdn
    end
    if !options.key?(:enable_starttls_auto)
      options[:enable_starttls_auto] = true
    end
    if !options.key?(:openssl_verify_mode)
      options[:openssl_verify_mode] = 'none'
    end
    mail = Channel::EmailBuild.build(attr, notification)
    smtp_params = {
      openssl_verify_mode: options[:openssl_verify_mode],
      address: options[:host],
      port: options[:port],
      domain: options[:domain],
      enable_starttls_auto: options[:enable_starttls_auto],
    }

    # set ssl if needed
    if options[:ssl].present?
      smtp_params[:ssl] = options[:ssl]
    end

    # add authentication only if needed
    if options[:user].present?
      smtp_params[:user_name] = options[:user]
      smtp_params[:password] = options[:password]
      smtp_params[:authentication] = options[:authentication]
    end
    mail.delivery_method :smtp, smtp_params
    mail.deliver
  end
end

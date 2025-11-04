# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::Smtp < Channel::Driver::BaseEmailOutbound
  # We're using the same timeouts like in Net::SMTP gem
  # but we would like to have the possibility to mock them for tests
  DEFAULT_OPEN_TIMEOUT = 30.seconds
  DEFAULT_READ_TIMEOUT = 60.seconds

  # Following SMTP error codes will be handled gracefully on notifications.
  # They will be logged at info level only and the code will not propagate up the error.
  # Other SMTP error codes will stop processing and exit with logging it at error level.
  #
  # 4xx - temporary issues.
  # 52x - permanent receiving server errors.
  # 55x - permanent receiving mailbox errors.
  SILENCABLE_SMTP_ERROR_CODES_FOR_NOTIFICATIONS = [400..499, 520..529, 550..559].freeze

  # Sends a message via SMTP
  #
  # @example
  # instance = Channel::Driver::Smtp.new
  # instance.deliver(
  #  {
  #    host:                 'some.host',
  #    port:                 25,
  #    enable_starttls_auto: true, # optional
  #    openssl_verify_mode:  'none', # optional
  #    user:                 'someuser',
  #    password:             'somepass'
  #    authentication:       nil, # nil, autodetection - to use certain schema use 'plain', 'login', 'xoauth2' or 'cram_md5'
  #  },
  #  mail_attributes,
  #  notification
  # )
  def deliver(options, attr, notification = false) # rubocop:disable Style/OptionalBooleanParameter
    # return if we run import mode
    return if Setting.get('import_mode')

    options = prepare_options(options, attr)

    attr = prepare_message_attrs(attr)

    smtp_params = build_smtp_params(options)

    Certificate::ApplySSLCertificates.ensure_fresh_ssl_context if options[:ssl] || options[:enable_starttls_auto]

    deliver_mail(attr, notification, :smtp, smtp_params)
  end

  def prepare_options(options, attr)
    # set smtp defaults
    if !options.key?(:port) || options[:port].blank?
      options[:port] = 25
    end

    if !options.key?(:ssl) && options[:port].to_i == 465
      options[:ssl] = true
    end

    if !options.key?(:domain)
      # set fqdn, if local fqdn - use domain of sender
      fqdn = Setting.get('fqdn')
      if fqdn =~ %r{(localhost|\.local^|\.loc^)}i && (attr['from'] || attr[:from])
        domain = Mail::Address.new(attr['from'] || attr[:from]).domain
        if domain
          fqdn = domain
        end
      end

      # https://github.com/zammad/zammad/pull/5635
      # remove port from the network address. RFC 5321 / 4.1.1.1. EHLO/HELO requires hostname withoutport.
      fqdn = fqdn.split(':').first

      options[:domain] = fqdn
    end

    if !options.key?(:enable_starttls_auto)
      options[:enable_starttls_auto] = true
    end

    options
  end

  def build_smtp_params(options)
    ssl_verify_mode = if options[:openssl_verify_mode].present?
                        options[:openssl_verify_mode]
                      else
                        options.fetch(:ssl_verify, true) ? 'peer' : 'none'
                      end

    smtp_params = {
      openssl_verify_mode:  ssl_verify_mode,
      address:              options[:host],
      port:                 options[:port],
      domain:               options[:domain],
      enable_starttls_auto: options[:enable_starttls_auto],
      open_timeout:         DEFAULT_OPEN_TIMEOUT,
      read_timeout:         DEFAULT_READ_TIMEOUT,
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

    smtp_params
  end

  private

  def server_identifier(options)
    "'#{options[:address]}' (port #{options[:port]})"
  end

  def deliver_mail_notification_silence?(e, mail)
    return false if !e.is_a?(Net::SMTPError)

    status_code = e.response&.status&.to_i

    return false if !status_code
    return false if SILENCABLE_SMTP_ERROR_CODES_FOR_NOTIFICATIONS.none? { |elem| elem.include? status_code }

    Rails.logger.info { "could not send email notification to (#{mail[:to]}) #{e}" }
    true
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class EmailHelper
  class Probe
    # Servers refuse a recipient with temporary and permanent codes alike, so every negative reply to
    #   the test mail counts, except 42x (the server closes the connection) and 43x, 53x (a missing login).
    OUTBOUND_REFUSAL_CODES = [400..419, 440..499, 500..529, 540..599].freeze

    #
    # Try to guess email channel configuration from basic user data.
    #
    def self.full(params)

      user, domain = EmailHelper.parse_email(params[:email])

      if !user || !domain
        return {
          result:   'invalid',
          messages: {
            email: "Invalid email '#{params[:email]}'."
          },
        }
      end

      # probe provider based settings
      provider_map = EmailHelper.provider(params[:email], params[:password])
      domains = [domain]

      # get mx records, try to find provider based on mx records
      mx_records = EmailHelper.mx_records(domain)
      domains.concat(mx_records)
      provider_map.each_value do |settings|
        domains.each do |domain_to_check|

          next if !domain_to_check.match?(%r{#{settings[:domain]}}i)

          # add folder to config if needed
          if params[:folder].present? && settings[:inbound] && settings[:inbound][:options]
            settings[:inbound][:options][:folder] = params[:folder]
          end

          config_set_verify_ssl(settings[:inbound], params)
          config_set_verify_ssl(settings[:outbound], params)

          # probe inbound
          Rails.logger.debug { "INBOUND PROBE PROVIDER: #{settings[:inbound].inspect}" }
          result_inbound = EmailHelper::Probe.inbound(settings[:inbound])
          Rails.logger.debug { "INBOUND RESULT PROVIDER: #{result_inbound.inspect}" }
          next if result_inbound[:result] != 'ok'

          # probe outbound
          Rails.logger.debug { "OUTBOUND PROBE PROVIDER: #{settings[:outbound].inspect}" }
          result_outbound = EmailHelper::Probe.outbound(settings[:outbound], params[:email])
          Rails.logger.debug { "OUTBOUND RESULT PROVIDER: #{result_outbound.inspect}" }
          next if result_outbound[:result] != 'ok'

          return {
            result:           'ok',
            content_messages: result_inbound[:content_messages],
            setting:          settings,
          }
        end
      end

      # probe guess settings

      # probe inbound
      inbound_mx = EmailHelper.provider_inbound_mx(user, params[:email], params[:password], mx_records)
      inbound_guess = EmailHelper.provider_inbound_guess(user, params[:email], params[:password], domain)
      inbound_map = inbound_mx + inbound_guess
      result = {
        result:  'ok',
        setting: {}
      }
      success = false
      inbound_map.each do |config|

        # add folder to config if needed
        if params[:folder].present? && config[:options]
          config[:options][:folder] = params[:folder]
        end

        # Add SSL verification flag to configuration, if needed.
        config_set_verify_ssl(config, params)

        Rails.logger.debug { "INBOUND PROBE GUESS: #{config.inspect}" }
        result_inbound = EmailHelper::Probe.inbound(config)
        Rails.logger.debug { "INBOUND RESULT GUESS: #{result_inbound.inspect}" }

        next if result_inbound[:result] != 'ok'

        success                    = true
        result[:setting][:inbound] = config
        result[:content_messages]  = result_inbound[:content_messages]

        break
      end

      # give up, no possible inbound found
      if !success
        return {
          result: 'failed',
          reason: 'inbound failed',
        }
      end

      # probe outbound
      outbound_mx = EmailHelper.provider_outbound_mx(user, params[:email], params[:password], mx_records)
      outbound_guess = EmailHelper.provider_outbound_guess(user, params[:email], params[:password], domain)
      outbound_map = outbound_mx + outbound_guess

      success = false
      outbound_map.each do |config|

        # Add SSL verification flag to configuration, if needed.
        config_set_verify_ssl(config, params)

        Rails.logger.debug { "OUTBOUND PROBE GUESS: #{config.inspect}" }
        result_outbound = EmailHelper::Probe.outbound(config, params[:email])
        Rails.logger.debug { "OUTBOUND RESULT GUESS: #{result_outbound.inspect}" }

        next if result_outbound[:result] != 'ok'

        success                     = true
        result[:setting][:outbound] = config
        break
      end

      # give up, no possible outbound found
      if !success
        return {
          result: 'failed',
          reason: 'outbound failed',
        }
      end
      Rails.logger.debug { "PROBE FULL SUCCESS: #{result.inspect}" }
      result
    end

    #
    # Validate an inbound email channel configuration.
    #
    def self.inbound(params)

      adapter = params[:adapter].downcase

      # validate adapter
      if !probeable_driver? adapter, :inbound
        return {
          result:  'failed',
          message: "Unknown adapter '#{adapter}'",
        }
      end

      # connection test
      result_inbound = {}
      begin
        driver_class    = "Channel::Driver::#{adapter.to_classname}".constantize
        driver_instance = driver_class.new
        result_inbound  = driver_instance.check_configuration(params[:options])
      rescue => e
        Rails.logger.debug { e }

        return {
          result:        'invalid',
          settings:      params,
          message:       e.message,
          message_human: translation(e.message),
          invalid_field: invalid_field(e.message),
        }
      end
      result_inbound
    end

    #
    # Validate an outbound email channel configuration.
    #
    # system_bcc: false leaves the BCC of the system out of the test mail, for a sender whose mails
    #   never carry it.
    def self.outbound(params, email, subject = nil, recipient: nil, system_bcc: true)
      recipient = recipient.presence

      raise ArgumentError, 'subject and recipient cannot be combined' if subject && recipient

      adapter = params[:adapter].downcase

      # validate adapter
      if !probeable_driver? adapter, :outbound
        return {
          result:  'failed',
          message: "Unknown adapter '#{adapter}'",
        }
      end

      mail = outbound_test_mail(email, subject, recipient)

      if subject.present?
        mail['X-Zammad-Test-Message'] = subject
      end
      mail['X-Zammad-Ignore']          = 'true'
      mail['X-Zammad-Fqdn']            = Setting.get('fqdn')
      mail['X-Zammad-Verify']          = 'true'
      mail['X-Zammad-Verify-Time']     = Time.zone.now.iso8601
      mail['X-Loop']                   = 'yes'
      mail['Precedence']               = 'bulk'
      mail['Auto-Submitted']           = 'auto-generated'
      mail['X-Auto-Response-Suppress'] = 'All'

      # test connection
      begin
        driver_class    = "Channel::Driver::#{adapter.to_classname}".constantize
        driver_instance = driver_class.new
        driver_instance.deliver(
          params[:options],
          mail,
          system_bcc:,
        )
      rescue => e
        Rails.logger.debug { e }

        reply_error = outbound_reply_error(e)
        message     = outbound_error_message(e, reply_error, params.dig(:options, :host))

        result = {
          result:        'invalid',
          settings:      params,
          message:       message,
          message_human: translation(message),
          invalid_field: invalid_field(message),
        }
        result[:refused] = true if outbound_refused?(reply_error)

        return result
      end
      {
        result: 'ok',
      }
    end

    # rubocop:disable-next Zammad/DetectTranslatableString
    def self.outbound_test_mail(email, subject, recipient)
      if subject
        return {
          from:    email,
          to:      email,
          subject: "Zammad Getting started Test Email #{subject}",
          body:    "This is a test email from Zammad to check if email sending and receiving work correctly.\n\nYou can ignore or delete this email.",
        }
      end

      body = if recipient
               'This is a test email from Zammad to verify if Zammad can send emails to this address.'
             else
               'This is a test email from Zammad to verify if Zammad can send emails to an external address.'
             end

      {
        from:    email,
        to:      recipient || 'verify-external-smtp-sending@discard.zammad.org',
        subject: 'This is a Test Email',
        body:    "#{body}\n\nIf you see this email, you can ignore or delete it.",
      }
    end

    # The driver re-raises with a plain message, and a QUIT that fails after a negative reply raises an
    #   error of its own. So the reply that ended the session is the earliest error of Net::SMTP among the causes.
    def self.outbound_reply_error(error)
      errors = Enumerator.produce(error, &:cause).take_while(&:itself)

      errors.rfind { |candidate| candidate.is_a?(Net::SMTPError) && candidate.response }
    end

    # After a failed QUIT the driver names that failure, so the reply of the server takes its place.
    def self.outbound_error_message(error, reply_error, host)
      return error.message if !reply_error || [error, error.cause].any? { |named| named.equal?(reply_error) }

      "#{host}: #{reply_error.message}"
    end

    def self.outbound_refused?(reply_error)
      # A reply of the session setup means that the connection or the login failed, whatever its code.
      return false if !reply_error || reply_error.is_a?(Net::SMTP::SessionSetupError)

      code = reply_error.response.status.to_i

      OUTBOUND_REFUSAL_CODES.any? { |range| range.include?(code) }
    end

    def self.invalid_field(message_backend)
      invalid_fields.each do |key, fields|
        return fields if message_backend.match?(%r{#{Regexp.escape(key)}}i)
      end
      {}
    end

    def self.invalid_fields
      {
        'authentication failed'                                     => { user: true, password: true },
        'Username and Password not accepted'                        => { user: true, password: true },
        'Incorrect username'                                        => { user: true, password: true },
        'Lookup failed'                                             => { user: true },
        'Invalid credentials'                                       => { user: true, password: true },
        'getaddrinfo: nodename nor servname provided, or not known' => { host: true },
        'getaddrinfo: Name or service not known'                    => { host: true },
        'No route to host'                                          => { host: true },
        'execution expired'                                         => { host: true },
        'Connection refused'                                        => { host: true },
        'Mailbox doesn\'t exist'                                    => { folder: true },
        'Folder doesn\'t exist'                                     => { folder: true },
        'Unknown Mailbox'                                           => { folder: true },
      }
    end

    def self.translation(message_backend)
      translations.each do |key, message_human|
        return message_human if message_backend.match?(%r{#{Regexp.escape(key)}}i)
      end
      nil
    end

    def self.translations
      {
        'authentication failed'                        => __('Authentication failed.'),
        'Username and Password not accepted'           => __('Authentication failed.'),
        'Incorrect username'                           => __('Authentication failed due to incorrect username.'),
        'Lookup failed'                                => __('Authentication failed due to incorrect username.'),
        'Invalid credentials'                          => __('Authentication failed due to incorrect credentials.'),
        'authentication not enabled'                   => __('Authentication not possible (not offered by the service)'),
        'nodename nor servname provided, or not known' => __('The hostname could not be found.'),
        'Name or service not known'                    => __('The hostname could not be found.'),
        'No route to host'                             => __('There is no route to this host.'),
        'execution expired'                            => __('This host cannot be reached.'),
        'Connection refused'                           => __('The connection was refused.'),
      }
    end

    def self.config_set_verify_ssl(config, params)
      return if !config[:options]

      if params.key?(:ssl_verify)
        config[:options][:ssl_verify] = params[:ssl_verify]
      elsif config[:options][:ssl] || config[:options][:start_tls]
        config[:options][:ssl_verify] = true
      else
        config[:options][:ssl_verify] ||= false
      end
    end

    # Returns all probeable drivers. Which are not limited to classic email drivers available for email setup.
    # Emailhelper.available_driver returns drivers available for generic email driver setup only.
    # So it needs to be extended with other drivers here
    def self.all_probeable_drivers
      EmailHelper
        .available_driver
        .tap do |elem|
          elem[:inbound][:microsoft_graph_inbound] = true
          elem[:outbound][:microsoft_graph_outbound] = true
        end
    end

    def self.probeable_driver?(name, direction)
      all_probeable_drivers[direction.to_sym].key? name.to_sym
    end
  end

end

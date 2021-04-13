# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class EmailHelper
  class Probe

=begin

get result of probe

  result = EmailHelper::Probe.full(
    email: 'znuny@example.com',
    password: 'somepassword',
    folder: 'some_folder', # optional im imap
  )

returns on success

  {
    result: 'ok',
    settings: {
      inbound: {
        adapter: 'imap',
        options: {
          host: 'imap.gmail.com',
          port: 993,
          ssl: true,
          user: 'some@example.com',
          password: 'password',
          folder: 'some_folder', # optional im imap
         },
      },
      outbound: {
        adapter: 'smtp',
        options: {
          host: 'smtp.gmail.com',
          port: 25,
          ssl: true,
          user: 'some@example.com',
          password: 'password',
        },
      },
    }
  }

returns on fail

  result = {
    result: 'failed',
  }

=end

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
            result:             'ok',
            content_messages:   result_inbound[:content_messages],
            archive_possible:   result_inbound[:archive_possible],
            archive_week_range: result_inbound[:archive_week_range],
            setting:            settings,
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

        Rails.logger.debug { "INBOUND PROBE GUESS: #{config.inspect}" }
        result_inbound = EmailHelper::Probe.inbound(config)
        Rails.logger.debug { "INBOUND RESULT GUESS: #{result_inbound.inspect}" }

        next if result_inbound[:result] != 'ok'

        success                     = true
        result[:setting][:inbound]  = config
        result[:content_messages]   = result_inbound[:content_messages]
        result[:archive_possible]   = result_inbound[:archive_possible]
        result[:archive_week_range] = result_inbound[:archive_week_range]

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

=begin

get result of inbound probe

  result = EmailHelper::Probe.inbound(
    adapter: 'imap',
    options: {
      host: 'imap.gmail.com',
      port: 993,
      ssl: true,
      user: 'some@example.com',
      password: 'password',
      folder: 'some_folder', # optional
    }
  )

returns on success

  {
    result: 'ok'
  }

returns on fail

  result = {
    result: 'invalid',
    settings: {
      host: 'imap.gmail.com',
      port: 993,
      ssl: true,
      user: 'some@example.com',
      password: 'password',
      folder: 'some_folder', # optional im imap
    },
    message: 'error message from used lib',
    message_human: 'translated error message, readable for humans',
  }

=end

    def self.inbound(params)

      adapter = params[:adapter].downcase

      # validate adapter
      if !EmailHelper.available_driver[:inbound][adapter.to_sym]
        return {
          result:  'failed',
          message: "Unknown adapter '#{adapter}'",
        }
      end

      # connection test
      result_inbound = {}
      begin
        require_dependency "channel/driver/#{adapter.to_filename}"

        driver_class    = "Channel::Driver::#{adapter.to_classname}".constantize
        driver_instance = driver_class.new
        result_inbound  = driver_instance.fetch(params[:options], nil, 'check')
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

=begin

get result of outbound probe

  result = EmailHelper::Probe.outbound(
    {
      adapter: 'smtp',
      options: {
        host: 'smtp.gmail.com',
        port: 25,
        ssl: true,
        user: 'some@example.com',
        password: 'password',
      }
    },
    'sender_and_recipient_of_test_email@example.com',
    'subject of probe email',
  )

returns on success

  {
    result: 'ok'
  }

returns on fail

  result = {
    result: 'invalid',
    settings: {
      host: 'stmp.gmail.com',
      port: 25,
      ssl: true,
      user: 'some@example.com',
      password: 'password',
    },
    message: 'error message from used lib',
    message_human: 'translated error message, readable for humans',
  }

=end

    def self.outbound(params, email, subject = nil)

      adapter = params[:adapter].downcase

      # validate adapter
      if !EmailHelper.available_driver[:outbound][adapter.to_sym]
        return {
          result:  'failed',
          message: "Unknown adapter '#{adapter}'",
        }
      end

      # prepare test email
      mail = if subject
               {
                 from:    email,
                 to:      email,
                 subject: "Zammad Getting started Test Email #{subject}",
                 body:    "This is a Test Email of Zammad to check if sending and receiving is working correctly.\n\nYou can ignore or delete this email.",
               }
             else
               {
                 from:    email,
                 to:      'emailtrytest@znuny.com',
                 subject: 'This is a Test Email',
                 body:    "This is a Test Email of Zammad to verify if Zammad can send emails to an external address.\n\nIf you see this email, you can ignore and delete it.",
               }
             end
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
        require_dependency "channel/driver/#{adapter.to_filename}"

        driver_class    = "Channel::Driver::#{adapter.to_classname}".constantize
        driver_instance = driver_class.new
        driver_instance.send(
          params[:options],
          mail,
        )
      rescue => e
        Rails.logger.debug { e }

        # check if sending email was ok, but mailserver rejected
        if !subject
          white_map = {
            'Recipient address rejected'                => true,
            'Sender address rejected: Domain not found' => true,
          }
          white_map.each_key do |key|

            next if !e.message.match?(%r{#{Regexp.escape(key)}}i)

            return {
              result:   'ok',
              settings: params,
              notice:   e.message,
            }
          end
        end

        return {
          result:        'invalid',
          settings:      params,
          message:       e.message,
          message_human: translation(e.message),
          invalid_field: invalid_field(e.message),
        }
      end
      {
        result: 'ok',
      }
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
        'authentication failed'                                     => 'Authentication failed!',
        'Username and Password not accepted'                        => 'Authentication failed!',
        'Incorrect username'                                        => 'Authentication failed, username incorrect!',
        'Lookup failed'                                             => 'Authentication failed, username incorrect!',
        'Invalid credentials'                                       => 'Authentication failed, invalid credentials!',
        'authentication not enabled'                                => 'Authentication not possible (not offered by the service)',
        'getaddrinfo: nodename nor servname provided, or not known' => 'Hostname not found!',
        'getaddrinfo: Name or service not known'                    => 'Hostname not found!',
        'No route to host'                                          => 'No route to host!',
        'execution expired'                                         => 'Host not reachable!',
        'Connection refused'                                        => 'Connection refused!',
      }
    end

  end

end

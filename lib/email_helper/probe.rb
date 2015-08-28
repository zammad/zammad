module EmailHelper
  class Probe

=begin

get result of probe

  result = EmailHelper::Probe.full(
    email: 'znuny@example.com',
    password: 'somepassword',
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
        result = {
          result: 'invalid',
          messages: {
            email: 'Invalid email.'
          },
        }
        return result
      end

      # probe provider based settings
      provider_map = EmailHelper.provider(params[:email], params[:password])
      domains = [domain]

      # get mx records, try to find provider based on mx records
      mx_records = EmailHelper.mx_records(domain)
      domains = domains.concat(mx_records)
      provider_map.each {|_provider, settings|
        domains.each {|domain_to_check|

          next if domain_to_check !~ /#{settings[:domain]}/i

          # probe inbound
          result = EmailHelper::Probe.inbound(settings[:inbound])
          return result if result[:result] != 'ok'

          # probe outbound
          result = EmailHelper::Probe.outbound(settings[:outbound], params[:email])
          return result if result[:result] != 'ok'

          result = {
            result: 'ok',
            setting: settings,
          }
          return result
        }
      }

      # probe guess settings

      # probe inbound
      inbound_mx = EmailHelper.provider_inbound_mx(user, params[:email], params[:password], mx_records)
      inbound_guess = EmailHelper.provider_inbound_guess(user, params[:email], params[:password], domain)
      inbound_map = inbound_mx + inbound_guess
      settings = {}
      success = false
      inbound_map.each {|config|
        Rails.logger.info "INBOUND PROBE: #{config.inspect}"
        result = EmailHelper::Probe.inbound( config )
        Rails.logger.info "INBOUND RESULT: #{result.inspect}"

        next if result[:result] != 'ok'

        success = true
        settings[:inbound] = config
        break
      }

      if !success
        result = {
          result: 'failed',
        }
        return result
      end

      # probe outbound
      outbound_mx = EmailHelper.provider_outbound_mx(user, params[:email], params[:password], mx_records)
      outbound_guess = EmailHelper.provider_outbound_guess(user, params[:email], params[:password], domain)
      outbound_map = outbound_mx + outbound_guess

      success = false
      outbound_map.each {|config|
        Rails.logger.info "OUTBOUND PROBE: #{config.inspect}"
        result = EmailHelper::Probe.outbound( config, params[:email] )
        Rails.logger.info "OUTBOUND RESULT: #{result.inspect}"

        next if result[:result] != 'ok'

        success = true
        settings[:outbound] = config
        break
      }

      if !success
        result = {
          result: 'failed',
        }
        return result
      end

      {
        result: 'ok',
        setting: settings,
      }
    end

=begin

get result of inbound probe

  result = EmailHelper::Probe.inbound(
    adapter: 'imap',
    settings: {
      host: 'imap.gmail.com',
      port: 993,
      ssl: true,
      user: 'some@example.com',
      password: 'password',
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
    },
    message: 'error message from used lib',
    message_human: 'translated error message, readable for humans',
  }

=end

    def self.inbound(params)

      adapter = params[:adapter].downcase

      # connection test
      begin

        # validate adapter
        if adapter !~ /^(imap|pop3)$/
          fail "Unknown adapter '#{adapter}'"
        end

        require "channel/driver/#{adapter.to_filename}"

        driver_class    = Object.const_get("Channel::Driver::#{adapter.to_classname}")
        driver_instance = driver_class.new
        driver_instance.fetch(params[:options], nil, 'check')

      rescue => e
        message_human = ''
        translations.each {|key, message|
          if e.message =~ /#{Regexp.escape(key)}/i
            message_human = message
          end
        }
        result = {
          result: 'invalid',
          settings: params,
          message: e.message,
          message_human: message_human,
        }
        return result
      end
      result = {
        result: 'ok',
      }
      result
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

      # prepare test email
      if subject
        mail = {
          :from             => email,
          :to               => email,
          :subject          => "Zammad Getting started Test Email #{subject}",
          :body             => "This is a Test Email of Zammad to check if sending and receiving is working correctly.\n\nYou can ignore or delete this email.",
          'x-zammad-ignore' => 'true',
        }
      else
        mail = {
          from: email,
          to: 'emailtrytest@znuny.com',
          subject: 'This is a Test Email',
          body: "This is a Test Email of Zammad to verify if Zammad can send emails to an external address.\n\nIf you see this email, you can ignore and delete it.",
        }
      end

      # test connection
      begin

        # validate adapter
        if adapter !~ /^(smtp|sendmail)$/
          fail "Unknown adapter '#{adapter}'"
        end

        # set smtp defaults
        if adapter =~ /^smtp$/
          if !params[:options].key?(:port)
            params[:options][:port] = 25
          end
          if !params[:options].key?(:ssl)
            params[:options][:ssl] = true
          end
        end

        require "channel/driver/#{adapter.to_filename}"

        driver_class    = Object.const_get("Channel::Driver::#{adapter.to_classname}")
        driver_instance = driver_class.new
        driver_instance.send(
            params[:options],
            mail,
        )
      rescue => e

        # check if sending email was ok, but mailserver rejected
        if !subject
          white_map = {
            'Recipient address rejected' => true,
          }
          white_map.each {|key, _message|

            next if e.message !~ /#{Regexp.escape(key)}/i

            result = {
              result: 'ok',
              settings: params,
              notice: e.message,
            }
            return result
          }
        end
        message_human = ''
        translations.each {|key, message|
          if e.message =~ /#{Regexp.escape(key)}/i
            message_human = message
          end
        }
        result = {
          result: 'invalid',
          settings: params,
          message: e.message,
          message_human: message_human,
        }
        return result
      end
      result = {
        result: 'ok',
      }
      result
    end

    def self.translations
      {
        'authentication failed'                                     => 'Authentication failed!',
        'Username and Password not accepted'                        => 'Authentication failed!',
        'Incorrect username'                                        => 'Authentication failed, username incorrect!',
        'Lookup failed'                                             => 'Authentication failed, username incorrect!',
        'Invalid credentials'                                       => 'Authentication failed, invalid credentials!',
        'getaddrinfo: nodename nor servname provided, or not known' => 'Hostname not found!',
        'getaddrinfo: Name or service not known'                    => 'Hostname not found!',
        'No route to host'                                          => 'No route to host!',
        'execution expired'                                         => 'Host not reachable!',
        'Connection refused'                                        => 'Connection refused!',
      }
    end

  end

end

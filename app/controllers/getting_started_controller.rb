# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'resolv'

class GettingStartedController < ApplicationController

=begin

Resource:
GET /api/v1/getting_started

Response:
{
  "master_user": 1,
  "groups": [
    {
      "name": "group1",
      "active":true
    },
    {
      "name": "group2",
      "active":true
    }
  ]
}

Test:
curl http://localhost/api/v1/getting_started -v -u #{login}:#{password}

=end

  def index

    # check if first user already exists
    return if setup_done_response

    # check it auto wizard is already done
    auto_wizard_admin = AutoWizard.setup
    if auto_wizard_admin

      # set current session user
      current_user_set(auto_wizard_admin)

      # set system init to done
      Setting.set( 'system_init_done', true )

      render json: {
        auto_wizard: true,
        setup_done: setup_done,
        import_mode: Setting.get('import_mode'),
        import_backend: Setting.get('import_backend'),
        system_online_service: Setting.get('system_online_service'),
      }
      return
    end

    # if master user already exists, we need to be authenticated
    if setup_done
      return if !authentication_check
    end

    # return result
    render json: {
      setup_done: setup_done,
      import_mode: Setting.get('import_mode'),
      import_backend: Setting.get('import_backend'),
      system_online_service: Setting.get('system_online_service'),
    }
  end

  def base

    # check admin permissions
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    # validate url
    messages = {}
    if !Setting.get('system_online_service')
      if !params[:url] || params[:url] !~ %r{^(http|https)://.+?$}
        messages[:url] = 'A URL looks like http://zammad.example.com'
      end
    end

    # validate organization
    if !params[:organization] || params[:organization].empty?
      messages[:organization] = 'Invalid!'
    end

    # validate image
    if params[:logo] && params[:logo] =~ /^data:image/i

      file = StaticAssets.data_url_attributes( params[:logo] )

      if !file[:content] || !file[:mime_type]
        messages[:logo] = 'Unable to process image upload.'
      end
    end

    if !messages.empty?
      render json: {
        result: 'invalid',
        messages: messages,
      }
      return
    end

    # split url in http_type and fqdn
    settings = {}
    if !Setting.get('system_online_service')
      if params[:url] =~ %r{/^(http|https)://(.+?)$}
        Setting.set('http_type', $1)
        settings[:http_type] = $1
        Setting.set('fqdn', $2)
        settings[:fqdn] = $2
      end
    end

    # save organization
    Setting.set('organization', params[:organization])
    settings[:organization] = params[:organization]

    # save image
    if params[:logo] && params[:logo] =~ /^data:image/i

      # data:image/png;base64
      file = StaticAssets.data_url_attributes( params[:logo] )

      # store image 1:1
      StaticAssets.store_raw( file[:content], file[:mime_type] )
    end

    if params[:logo_resize] && params[:logo_resize] =~ /^data:image/i

      # data:image/png;base64
      file = StaticAssets.data_url_attributes( params[:logo_resize] )

      # store image 1:1
      settings[:product_logo] = StaticAssets.store( file[:content], file[:mime_type] )
    end

    # set changed settings
    settings.each {|key, value|
      Setting.set(key, value)
    }

    render json: {
      result: 'ok',
      settings: settings,
    }
  end

  def email_probe

    # check admin permissions
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    # validation
    user   = nil
    domain = nil
    if params[:email] =~ /^(.+?)@(.+?)$/
      user   = $1
      domain = $2
    end

    if !user || !domain
      render json: {
        result: 'invalid',
        messages: {
          email: 'Invalid email.'
        },
      }
      return
    end

    # check domain based attributes
    provider_map = {
      google: {
        domain: 'gmail.com|googlemail.com|gmail.de',
        inbound: {
          adapter: 'imap',
          options: {
            host: 'imap.gmail.com',
            port: '993',
            ssl: true,
            user: params[:email],
            password: params[:password],
          },
        },
        outbound: {
          adapter: 'smtp',
          options: {
            host: 'smtp.gmail.com',
            port: '25',
            start_tls: true,
            user: params[:email],
            password: params[:password],
          }
        },
      },
      microsoft: {
        domain: 'outlook.com|hotmail.com',
        inbound: {
          adapter: 'imap',
          options: {
            host: 'imap-mail.outlook.com',
            port: '993',
            ssl: true,
            user: params[:email],
            password: params[:password],
          },
        },
        outbound: {
          adapter: 'smtp',
          options: {
            host: 'smtp-mail.outlook.com',
            port: 25,
            start_tls: true,
            user: params[:email],
            password: params[:password],
          }
        },
      },
    }

    # probe based on email domain and mx
    domains = [domain]
    mail_exchangers = mxers(domain)
    if mail_exchangers && mail_exchangers[0]
      logger.info "MX for #{domain}: #{mail_exchangers} - #{mail_exchangers[0][0]}"
    end
    if mail_exchangers && mail_exchangers[0] && mail_exchangers[0][0]
      domains.push mail_exchangers[0][0]
    end
    provider_map.each {|provider, settings|
      domains.each {|domain_to_check|
        if domain_to_check =~ /#{settings[:domain]}/i

          # probe inbound
          result = email_probe_inbound( settings[:inbound] )
          if result[:result] != 'ok'
            render json: result
            return # rubocop:disable Lint/NonLocalExitFromIterator
          end

          # probe outbound
          result = email_probe_outbound( settings[:outbound], params[:email] )
          if result[:result] != 'ok'
            render json: result
            return # rubocop:disable Lint/NonLocalExitFromIterator
          end

          render json: {
            result: 'ok',
            setting: settings,
          }
          return # rubocop:disable Lint/NonLocalExitFromIterator
        end
      }
    }

    # probe inbound
    inbound_map = []
    if mail_exchangers && mail_exchangers[0] && mail_exchangers[0][0]
      inbound_mx = [
        {
          adapter: 'imap',
          options: {
            host: mail_exchangers[0][0],
            port: 993,
            ssl: true,
            user: user,
            password: params[:password],
          },
        },
        {
          adapter: 'imap',
          options: {
            host: mail_exchangers[0][0],
            port: 993,
            ssl: true,
            user: params[:email],
            password: params[:password],
          },
        },
      ]
      inbound_map = inbound_map + inbound_mx
    end
    inbound_auto = [
      {
        adapter: 'imap',
        options: {
          host: "mail.#{domain}",
          port: 993,
          ssl: true,
          user: user,
          password: params[:password],
        },
      },
      {
        adapter: 'imap',
        options: {
          host: "mail.#{domain}",
          port: 993,
          ssl: true,
          user: params[:email],
          password: params[:password],
        },
      },
      {
        adapter: 'imap',
        options: {
          host: "imap.#{domain}",
          port: 993,
          ssl: true,
          user: user,
          password: params[:password],
        },
      },
      {
        adapter: 'imap',
        options: {
          host: "imap.#{domain}",
          port: 993,
          ssl: true,
          user: params[:email],
          password: params[:password],
        },
      },
      {
        adapter: 'pop3',
        options: {
          host: "mail.#{domain}",
          port: 995,
          ssl: true,
          user: user,
          password: params[:password],
        },
      },
      {
        adapter: 'pop3',
        options: {
          host: "mail.#{domain}",
          port: 995,
          ssl: true,
          user: params[:email],
          password: params[:password],
        },
      },
      {
        adapter: 'pop3',
        options: {
          host: "pop.#{domain}",
          port: 995,
          ssl: true,
          user: user,
          password: params[:password],
        },
      },
      {
        adapter: 'pop3',
        options: {
          host: "pop.#{domain}",
          port: 995,
          ssl: true,
          user: params[:email],
          password: params[:password],
        },
      },
      {
        adapter: 'pop3',
        options: {
          host: "pop3.#{domain}",
          port: 995,
          ssl: true,
          user: user,
          password: params[:password],
        },
      },
      {
        adapter: 'pop3',
        options: {
          host: "pop3.#{domain}",
          port: 995,
          ssl: true,
          user: params[:email],
          password: params[:password],
        },
      },
    ]
    inbound_map = inbound_map + inbound_auto
    settings = {}
    success = false
    inbound_map.each {|config|
      logger.info "INBOUND PROBE: #{config.inspect}"
      result = email_probe_inbound( config )
      logger.info "INBOUND RESULT: #{result.inspect}"
      if result[:result] == 'ok'
        success = true
        settings[:inbound] = config
        break
      end
    }

    if !success
      render json: {
        result: 'failed',
      }
      return
    end

    # probe outbound
    outbound_map = []
    if mail_exchangers && mail_exchangers[0] && mail_exchangers[0][0]
      outbound_mx = [
        {
          adapter: 'smtp',
          options: {
            host: mail_exchangers[0][0],
            port: 25,
            start_tls: true,
            user: user,
            password: params[:password],
          },
        },
        {
          adapter: 'smtp',
          options: {
            host: mail_exchangers[0][0],
            port: 25,
            start_tls: true,
            user: params[:email],
            password: params[:password],
          },
        },
        {
          adapter: 'smtp',
          options: {
            host: mail_exchangers[0][0],
            port: 465,
            start_tls: true,
            user: user,
            password: params[:password],
          },
        },
        {
          adapter: 'smtp',
          options: {
            host: mail_exchangers[0][0],
            port: 465,
            start_tls: true,
            user: params[:email],
            password: params[:password],
          },
        },
      ]
      outbound_map = outbound_map + outbound_mx
    end
    outbound_auto = [
      {
        adapter: 'smtp',
        options: {
          host: "mail.#{domain}",
          port: 25,
          start_tls: true,
          user: user,
          password: params[:password],
        },
      },
      {
        adapter: 'smtp',
        options: {
          host: "mail.#{domain}",
          port: 25,
          start_tls: true,
          user: params[:email],
          password: params[:password],
        },
      },
      {
        adapter: 'smtp',
        options: {
          host: "mail.#{domain}",
          port: 465,
          start_tls: true,
          user: user,
          password: params[:password],
        },
      },
      {
        adapter: 'smtp',
        options: {
          host: "mail.#{domain}",
          port: 465,
          start_tls: true,
          user: params[:email],
          password: params[:password],
        },
      },
      {
        adapter: 'smtp',
        options: {
          host: "smtp.#{domain}",
          port: 25,
          start_tls: true,
          user: user,
          password: params[:password],
        },
      },
      {
        adapter: 'smtp',
        options: {
          host: "smtp.#{domain}",
          port: 25,
          start_tls: true,
          user: params[:email],
          password: params[:password],
        },
      },
      {
        adapter: 'smtp',
        options: {
          host: "smtp.#{domain}",
          port: 465,
          start_tls: true,
          user: user,
          password: params[:password],
        },
      },
      {
        adapter: 'smtp',
        options: {
          host: "smtp.#{domain}",
          port: 465,
          start_tls: true,
          user: params[:email],
          password: params[:password],
        },
      },
    ]

    success = false
    outbound_map.each {|config|
      logger.info "OUTBOUND PROBE: #{config.inspect}"
      result = email_probe_outbound( config, params[:email] )
      logger.info "OUTBOUND RESULT: #{result.inspect}"
      if result[:result] == 'ok'
        success = true
        settings[:outbound] = config
        break
      end
    }

    if !success
      render json: {
        result: 'failed',
      }
      return
    end

    render json: {
      result: 'ok',
      setting: settings,
    }
  end

  def email_outbound

    # check admin permissions
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    # validate params
    if !params[:adapter]
      render json: {
        result: 'invalid',
      }
      return
    end

    # connection test
    result = email_probe_outbound( params, params[:email] )

    render json: result
  end

  def email_inbound

    # check admin permissions
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    # validate params
    if !params[:adapter]
      render json: {
        result: 'invalid',
      }
      return
    end

    # connection test
    result = email_probe_inbound( params )

    render json: result
  end

  def email_verify

    # check admin permissions
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    # send verify email to inbox
    if !params[:subject]
      subject = '#' + rand(99_999_999_999).to_s
    else
      subject = params[:subject]
    end
    result = email_probe_outbound( params[:outbound], params[:meta][:email], subject )

    (1..5).each {|loop|
      sleep 10

      # fetch mailbox
      found = nil

      begin
        if params[:inbound][:adapter] =~ /^imap$/i
          found = Channel::IMAP.new.fetch( { options: params[:inbound][:options] }, 'verify', subject )
        else
          found = Channel::POP3.new.fetch( { options: params[:inbound][:options] }, 'verify', subject )
        end
      rescue Exception => e
        render json: {
          result: 'invalid',
          message: e.to_s,
          subject: subject,
        }
        return # rubocop:disable Lint/NonLocalExitFromIterator
      end

      if found && found == 'verify ok'

        # remember address
        address = EmailAddress.where( email: params[:meta][:email] ).first
        if !address
          address = EmailAddress.first
        end
        if address
          address.update_attributes(
            realname: params[:meta][:realname],
            email: params[:meta][:email],
            active: 1,
            updated_by_id: 1,
            created_by_id: 1,
          )
        else
          EmailAddress.create(
            realname: params[:meta][:realname],
            email: params[:meta][:email],
            active: 1,
            updated_by_id: 1,
            created_by_id: 1,
          )
        end

        # store mailbox
        Channel.create(
          area: 'Email::Inbound',
          adapter: params[:inbound][:adapter],
          options: params[:inbound][:options],
          group_id: 1,
          active: 1,
          updated_by_id: 1,
          created_by_id: 1,
        )

        # save settings
        if params[:outbound][:adapter] =~ /^smtp$/i
          smtp = Channel.where( adapter: 'SMTP', area: 'Email::Outbound' ).first
          smtp.options = params[:outbound][:options]
          smtp.active  = true
          smtp.save!
          sendmail = Channel.where( adapter: 'Sendmail' ).first
          sendmail.active = false
          sendmail.save!
        else
          sendmail = Channel.where( adapter: 'Sendmail', area: 'Email::Outbound' ).first
          sendmail.options = {}
          sendmail.active  = true
          sendmail.save!
          smtp = Channel.where( adapter: 'SMTP' ).first
          smtp.active = false
          smtp.save
        end

        render json: {
          result: 'ok',
        }
        return # rubocop:disable Lint/NonLocalExitFromIterator
      end
    }

    # check delivery for 30 sek.
    render json: {
      result: 'invalid',
      message: 'Verification Email not found in mailbox.',
      subject: subject,
    }
  end

  private

  def email_probe_outbound(params, email, subject = nil)

    # validate params
    if !params[:adapter]
      result = {
        result: 'invalid',
        message: 'Invalid, need adapter!',
      }
      return result
    end

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
        subject: 'test',
        body: 'test',
      }
    end

    # test connection
    translation_map = {
      'authentication failed'                                     => 'Authentication failed!',
      'Incorrect username'                                        => 'Authentication failed!',
      'getaddrinfo: nodename nor servname provided, or not known' => 'Hostname not found!',
      'No route to host'                                          => 'No route to host!',
      'Connection refused'                                        => 'Connection refused!',
    }
    if params[:adapter] =~ /^smtp$/i

      # in case, fill missing params
      if !params[:options].key?(:port)
        params[:options][:port] = 25
      end
      if !params[:options].key?(:ssl)
        params[:options][:ssl] = true
      end

      begin
        Channel::SMTP.new.send(
          mail,
          {
            options: params[:options]
          }
        )
      rescue Exception => e

        # check if sending email was ok, but mailserver rejected
        if !subject
          white_map = {
            'Recipient address rejected' => true,
          }
          white_map.each {|key, message|
            if e.message =~ /#{Regexp.escape(key)}/i
              result = {
                result: 'ok',
                settings: params,
                notice: e.message,
              }
              return result
            end
          }
        end
        message_human = ''
        translation_map.each {|key, message|
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
      return result
    end

    begin
      Channel::Sendmail.new.send(
        mail,
        nil
      )
    rescue Exception => e
      message_human = ''
      translation_map.each {|key, message|
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

  def email_probe_inbound(params)

    # validate params
    if !params[:adapter]
      raise 'need :adapter param'
    end

    # connection test
    translation_map = {
      'authentication failed'                                     => 'Authentication failed!',
      'Incorrect username'                                        => 'Authentication failed!',
      'getaddrinfo: nodename nor servname provided, or not known' => 'Hostname not found!',
      'No route to host'                                          => 'No route to host!',
      'Connection refused'                                        => 'Connection refused!',
    }
    if params[:adapter] =~ /^imap$/i

      begin
        Channel::IMAP.new.fetch( { options: params[:options] }, 'check' )
      rescue Exception => e
        message_human = ''
        translation_map.each {|key, message|
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
      return result
    end

    begin
      Channel::POP3.new.fetch( { options: params[:options] }, 'check' )
    rescue Exception => e
      message_human = ''
      translation_map.each {|key, message|
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

  def mxers(domain)
    begin
      mxs = Resolv::DNS.open do |dns|
        ress = dns.getresources(domain, Resolv::DNS::Resource::IN::MX)
        ress.map { |r| [r.exchange.to_s, IPSocket.getaddress(r.exchange.to_s), r.preference] }
      end
    rescue Exception => e
      logger.error e.message
      logger.error e.backtrace.inspect
    end
    mxs
  end

  def setup_done
    #return false
    count = User.all.count()
    done = true
    if count <= 2
      done = false
    end
    done
  end

  def setup_done_response
    if !setup_done
      return false
    end

    # get all groups
    groups = Group.where( active: true )

    # get email addresses
    addresses = EmailAddress.where( active: true )

    render json: {
      setup_done: true,
      import_mode: Setting.get('import_mode'),
      import_backend: Setting.get('import_backend'),
      system_online_service: Setting.get('system_online_service'),
      addresses: addresses,
      groups: groups,
    }
    true
  end

end

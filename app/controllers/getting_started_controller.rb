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
    return if auto_wizard_enabled_response

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

  def auto_wizard_admin

    # check if system setup is already done
    return if setup_done_response

    # check it auto wizard is enabled
    if !AutoWizard.enabled?
      render json: {
        auto_wizard: false,
      }
      return
    end

    # verify auto wizard file
    auto_wizard_data = AutoWizard.data
    if !auto_wizard_data || auto_wizard_data.empty?
      render json: {
        auto_wizard: true,
        auto_wizard_success: false,
        message: 'Invalid auto wizard file.',
      }
      return
    end

    # verify auto wizard token
    if auto_wizard_data['Token'] && auto_wizard_data['Token'] != params[:token]
      render json: {
        auto_wizard: true,
        auto_wizard_success: false,
      }
      return
    end

    # execute auto wizard
    auto_wizard_admin = AutoWizard.setup
    if !auto_wizard_admin
      render json: {
        auto_wizard: true,
        auto_wizard_success: false,
        message: 'Error during execution of auto wizard.',
      }
      return
    end

    # set current session user
    current_user_set(auto_wizard_admin)

    # set system init to done
    Setting.set('system_init_done', true)

    render json: {
      auto_wizard: true,
      auto_wizard_success: true,
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

    # probe settings based on email and password
    render json: EmailHelper::Probe.full(
      email: params[:email],
      password: params[:password],
    )
  end

  def email_outbound

    # check admin permissions
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    # connection test
    render json: EmailHelper::Probe.outbound(params, params[:email])
  end

  def email_inbound

    # check admin permissions
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    # connection test
    render json: EmailHelper::Probe.inbound(params)
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

    result = EmailHelper::Verify.email(
      outbound: params[:outbound],
      inbound: params[:inbound],
      sender: params[:meta][:email],
      subject: subject,
    )

    # check delivery for 30 sek.
    if result[:result] != 'ok'
      render json: result
      return
    end

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
  end

  private

  def auto_wizard_enabled_response
    return false if !AutoWizard.enabled?

    render json: {
      auto_wizard: true
    }
    true
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
    return false if !setup_done

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
      config: config_to_update,
    }
    true
  end

  def config_to_update
    {
      product_logo: Setting.get('product_logo')
    }
  end

end

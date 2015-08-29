# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class ChannelsController < ApplicationController
  before_action :authentication_check

=begin

Resource:
GET /api/v1/channels/#{id}.json

Response example 1:

{
  "id":1,
  "area":"Email::Account",
  "group_id:": 1,
  "options":{
    "inbound": {
      "adapter":"IMAP",
      "options": {
      "host":"mail.example.com",
      "user":"some_user",
      "password":"some_password",
      "ssl":true
    },
    "outbound":{
      "adapter":"SMTP",
      "options": {
      "host":"mail.example.com",
      "user":"some_user",
      "password":"some_password",
      "start_tls":true
    }
  },
  "active":true,
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "updated_by_id":2.
  "created_by_id":2,
}

Response example 2:

{
  "id":1,
  "area":"Twitter::Account",
  "group_id:": 1,
  "options":{
    "adapter":"Twitter",
    "auth": {
      "consumer_key":"PJ4c3dYYRtSZZZdOKo8ow",
      "consumer_secret":"ggAdnJE2Al1Vv0cwwvX5bdvKOieFs0vjCIh5M8Dxk",
      "oauth_token":"293437546-xxRa9g74CercnU5AvY1uQwLLGIYrV1ezYtpX8oKW",
      "oauth_token_secret":"ju0E4l9OdY2Lh1iTKMymAu6XVfOaU2oGxmcbIMRZQK4",
    },
    "sync":{
      "search":[
        {
          "term":"#otrs",
          "type": "mixed", # optional, possible 'mixed' (default), 'recent', 'popular'
          "group_id:": 1,
          "limit": 1, # optional
        },
        {
          "term":"#zombie23",
          "group_id:": 2,
        },
        {
          "term":"#otterhub",
          "group_id:": 3,
        }
      ],
      "mentions" {
        "group_id:": 4,
        "limit": 100, # optional
      },
      "direct_messages": {
        "group_id:": 4,
        "limit": 1, # optional
      }
    }
  },
  "active":true,
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "updated_by_id":2.
  "created_by_id":2,
}

Test:
curl http://localhost/api/v1/channels/#{id}.json -v -u #{login}:#{password}

=end

  def show
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    return if !check_access
    model_show_render(Channel, params)
  end

=begin

Resource:
POST /api/v1/channels.json

Payload:
{
  "area":"Email::Account",
  "group_id:": 1,
  "options":{
    "inbound":
      "adapter":"IMAP",
      "options":{
        "host":"mail.example.com",
        "user":"some_user",
        "password":"some_password",
        "ssl":true
      },
    },
    "outbound":{
      "adapter":"SMTP",
      "options": {
      "host":"mail.example.com",
      "user":"some_user",
      "password":"some_password",
      "start_tls":true
    }
  },
  "active":true,
}

Response:
{
  "area":"Email::Account",
  ...
}

Test:
curl http://localhost/api/v1/channels.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def create
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_create_render(Channel, params)
  end

=begin

Resource:
PUT /api/v1/channels/{id}.json

Payload:
{
  "id":1,
  "area":"Email::Account",
  "group_id:": 1,
  "options":{
    "inbound":
      "adapter":"IMAP",
      "options":{
        "host":"mail.example.com",
        "user":"some_user",
        "password":"some_password",
        "ssl":true
      },
    },
    "outbound":{
      "adapter":"SMTP",
      "options": {
      "host":"mail.example.com",
      "user":"some_user",
      "password":"some_password",
      "start_tls":true
    }
  },
  "active":true,
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/channels.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def update
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    return if !check_access
    model_update_render(Channel, params)
  end

=begin

Resource:
DELETE /api/v1/channels/{id}.json

Response:
{}

Test:
curl http://localhost/api/v1/channels.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X DELETE

=end

  def destroy
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    return if !check_access
    model_destory_render(Channel, params)
  end

  def email_index
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    system_online_service = Setting.get('system_online_service')
    accounts_fixed = []
    assets = {}
    Channel.all.each {|channel|
      if system_online_service && channel.preferences && channel.preferences['online_service_disable']
        email_addresses = EmailAddress.where(channel_id: channel.id)
        email_addresses.each {|email_address|
          accounts_fixed.push email_address
        }
        next
      end
      assets = channel.assets(assets)
    }
    EmailAddress.all.each {|email_address|
      next if system_online_service && email_address.preferences && email_address.preferences['online_service_disable']
      assets = email_address.assets(assets)
    }
    render json: {
      accounts_fixed: accounts_fixed,
      assets: assets,
    }
  end

  def email_probe

    # check admin permissions
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    # probe settings based on email and password
    result = EmailHelper::Probe.full(
      email: params[:email],
      password: params[:password],
    )

    # verify if user+host already exists
    if result[:result] == 'ok'
      return if email_account_duplicate?(result)
    end

    render json: result
  end

  def email_outbound

    # check admin permissions
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    # verify access
    return if !check_access(params[:channel_id]) if params[:channel_id]

    # connection test
    render json: EmailHelper::Probe.outbound(params, params[:email])
  end

  def email_inbound

    # check admin permissions
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    # verify access
    return if !check_access(params[:channel_id]) if params[:channel_id]

    # connection test
    result = EmailHelper::Probe.inbound(params)

    # check account duplicate
    return if email_account_duplicate?({ setting: { inbound: params } }, params[:channel_id])

    render json: result
  end

  def email_verify

    # check admin permissions
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    email = params[:email] || params[:meta][:email]
    email = email.downcase
    channel_id = params[:channel_id]

    # verify access
    return if !check_access(channel_id) if channel_id

    # check account duplicate
    return if email_account_duplicate?({ setting: { inbound: params[:inbound] } }, channel_id)

    # check delivery for 30 sek.
    result = EmailHelper::Verify.email(
      outbound: params[:outbound],
      inbound: params[:inbound],
      sender: email,
      subject: params[:subject],
    )

    if result[:result] != 'ok'
      render json: result
      return
    end

    # update account
    if channel_id
      channel = Channel.find(channel_id)
      channel.update_attributes(
        options: {
          inbound: params[:inbound],
          outbound: params[:outbound],
        },
        last_log_in: nil,
        last_log_out: nil,
        status_in: 'ok',
        status_out: 'ok',
      )
      render json: {
        result: 'ok',
      }
      return
    end

    # create new account
    channel = Channel.create(
      area: 'Email::Account',
      options: {
        inbound: params[:inbound],
        outbound: params[:outbound],
      },
      last_log_in: nil,
      last_log_out: nil,
      status_in: 'ok',
      status_out: 'ok',
      active: true,
      group_id: Group.first.id,
    )

    # remember address && set channel for email address
    address = EmailAddress.find_by(email: email)

    # if we are on initial setup, use already exisiting dummy email address
    if Channel.count == 1
      address = EmailAddress.first
    end

    if address
      address.update_attributes(
        realname: params[:meta][:realname],
        email: email,
        active: true,
        channel_id: channel.id,
      )
    else
      address = EmailAddress.create(
        realname: params[:meta][:realname],
        email: email,
        active: true,
        channel_id: channel.id,
      )
    end

    render json: {
      result: 'ok',
    }
  end

  def email_notification

    return if !check_online_service

    # check admin permissions
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    adapter = params[:adapter].downcase

    # validate adapter
    if adapter !~ /^(smtp|sendmail)$/
      render json: {
        result: 'failed',
        message: "Unknown adapter '#{adapter}'",
      }
      return
    end

    email = Setting.get('notification_sender')

    # connection test
    result = EmailHelper::Probe.outbound(params, email)

    # save settings
    if result[:result] == 'ok'

      Channel.where(area: 'Email::Notification').each {|channel|
        active = false
        if adapter =~ /^#{channel.options[:outbound][:adapter]}$/i
          active = true
          channel.options = {
            outbound: {
              adapter: adapter,
              options: params[:options],
            },
          }
          channel.status_out   = 'ok'
          channel.last_log_out = nil
        end
        channel.active = active
        channel.save
      }
    end
    render json: result
  end

  private

  def email_account_duplicate?(result, channel_id = nil)
    Channel.where(area: 'Email::Account').each {|channel|
      next if !channel.options
      next if !channel.options[:inbound]
      next if !channel.options[:inbound][:adapter]
      next if channel.options[:inbound][:adapter] != result[:setting][:inbound][:adapter]
      next if channel.options[:inbound][:options][:host] != result[:setting][:inbound][:options][:host]
      next if channel.options[:inbound][:options][:user] != result[:setting][:inbound][:options][:user]
      next if channel.id.to_s == channel_id.to_s
      render json: {
        result: 'duplicate',
        message: 'Account already exists!',
      }
      return true
    }
    false
  end

  def check_online_service
    return true if !Setting.get('system_online_service')
    response_access_deny
    false
  end

  def check_access(id = nil)
    if !id
      id = params[:id]
    end
    return true if !Setting.get('system_online_service')

    channel = Channel.find(id)
    return true if channel.preferences && !channel.preferences[:online_service_disable]

    response_access_deny
    false
  end
end

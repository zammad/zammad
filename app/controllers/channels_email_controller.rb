# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ChannelsEmailController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  SENSITIVE_FIELDS = %i[
    options.password
    settings.options.password
  ].freeze

  def index
    system_online_service = Setting.get('system_online_service')
    account_channel_ids = []
    notification_channel_ids = []
    email_address_ids = []
    not_used_email_address_ids = []
    accounts_fixed = []
    assets = {}
    Channel.reorder(:id).each do |channel|
      if system_online_service && channel.preferences && channel.preferences['online_service_disable']
        email_addresses = EmailAddress.where(channel_id: channel.id)
        email_addresses.each do |email_address|
          accounts_fixed.push email_address
        end
        next
      end
      assets = channel.assets(assets)
      if channel.area == 'Email::Account'
        account_channel_ids.push channel.id
      elsif channel.area == 'Email::Notification' && channel.active
        notification_channel_ids.push channel.id
      end
    end
    EmailAddress.all.each do |email_address|
      next if system_online_service && email_address.preferences && email_address.preferences['online_service_disable']

      email_address_ids.push email_address.id
      assets = email_address.assets(assets)
      if !email_address.channel_id || !email_address.active || !Channel.exists?(id: email_address.channel_id)
        not_used_email_address_ids.push email_address.id
      end
    end
    render json: {
      accounts_fixed:             accounts_fixed,
      assets:                     assets,
      account_channel_ids:        account_channel_ids,
      notification_channel_ids:   notification_channel_ids,
      email_address_ids:          email_address_ids,
      not_used_email_address_ids: not_used_email_address_ids,
      channel_driver:             {
        email: EmailHelper.available_driver,
      },
      config:                     {
        notification_sender: Setting.get('notification_sender'),
      }
    }
  end

  def probe

    # probe settings based on email and password
    result = EmailHelper::Probe.full(
      email:    params[:email],
      password: params[:password],
      folder:   params[:folder],
    )

    # verify if user+host already exists
    return if result[:result] == 'ok' && account_duplicate?(result)

    render json: result
  end

  def outbound

    # verify access
    return if params[:channel_id] && !check_access(params[:channel_id])

    channel          = Channel.find_by(id: params[:channel_id])
    original_options = channel&.options&.dig(:outbound)
    unmasked_params  = unmask_sensitive_params(params.permit!.to_h, original_options)

    # connection test
    result = EmailHelper::Probe.outbound(unmasked_params, params[:email])

    render json: mask_sensitive_values(result, nil)
  end

  def inbound

    # verify access
    return if params[:channel_id] && !check_access(params[:channel_id])

    channel          = Channel.find_by(id: params[:channel_id])
    original_options = channel&.options&.dig(:inbound)
    unmasked_params  = unmask_sensitive_params(params.permit!.to_h, original_options)

    # connection test
    result = EmailHelper::Probe.inbound(unmasked_params)

    # check account duplicate
    return if account_duplicate?({ setting: { inbound: unmasked_params } }, params[:channel_id])

    render json: mask_sensitive_values(result, nil)
  end

  def verify
    params.permit!
    email      = (params[:email] || params[:meta][:email]).downcase
    channel_id = params[:channel_id]

    # verify access
    return if channel_id && !check_access(channel_id)

    channel                   = Channel.find_by(id: channel_id)
    original_options_inbound  = channel&.options&.dig(:inbound)
    original_options_outbound = channel&.options&.dig(:outbound)
    unmasked_params_inbound   = unmask_sensitive_params(params[:inbound].to_h, original_options_inbound)
    unmasked_params_outbound  = unmask_sensitive_params(params[:outbound].to_h, original_options_outbound)

    # check account duplicate
    return if account_duplicate?({ setting: { inbound: params[:inbound] } }, channel_id)

    # check delivery for 30 sec.
    result = EmailHelper::Verify.email(
      outbound: unmasked_params_outbound,
      inbound:  unmasked_params_inbound,
      sender:   email,
      subject:  params[:subject],
    )

    if result[:result] != 'ok'
      render json: mask_sensitive_values(result, nil)
      return
    end

    # fallback
    if !params[:group_id]
      params[:group_id] = Group.first.id
    end

    # update account
    if channel_id
      channel = Channel.find(channel_id)
      channel.update!(
        options:      {
          inbound:  unmasked_params_inbound,
          outbound: unmasked_params_outbound,
        },
        group_id:     params[:group_id],
        last_log_in:  nil,
        last_log_out: nil,
        status_in:    'ok',
        status_out:   'ok',
      )

      handle_group_email_address(channel)

      render json: mask_sensitive_values(result, nil)
      return
    end

    ::Service::Channel::Email::Create.execute(
      inbound_configuration:  unmasked_params_inbound,
      outbound_configuration: unmasked_params_outbound,
      group:                  ::Group.find(params[:group_id]),
      email_address:          email,
      email_realname:         params[:meta][:realname],
      group_email_address:    handle_group_email_address?,
    )

    render json: mask_sensitive_values(result, nil)
  end

  def enable
    channel = Channel.find_by(id: params[:id], area: 'Email::Account')
    channel.active = true
    channel.save!
    render json: {}
  end

  def disable
    channel = Channel.find_by(id: params[:id], area: 'Email::Account')
    channel.active = false
    channel.save!
    render json: {}
  end

  def destroy
    channel = Channel.find_by(id: params[:id], area: 'Email::Account')
    channel.destroy
    render json: {}
  end

  def group
    check_access
    channel = Channel.find_by(id: params[:id], area: 'Email::Account')
    channel.group_id = params[:group_id]
    channel.save!

    handle_group_email_address(channel)

    render json: {}
  end

  def notification
    params.permit!

    check_online_service

    adapter = params[:adapter].downcase

    email = Setting.get('notification_sender')

    channel = Channel
      .where(area: 'Email::Notification')
      .find { |elem| elem.options.dig(:outbound, :adapter).casecmp?(adapter) }

    original_options = channel&.options&.dig(:outbound)
    unmasked_params  = unmask_sensitive_params(params.permit!.to_h, original_options)

    # connection test
    result = EmailHelper::Probe.outbound(unmasked_params, email)

    # save settings
    if result[:result] == 'ok'
      Service::System::SetEmailNotificationConfiguration
        .execute(
          adapter:,
          new_configuration: unmasked_params[:options].to_h
        )
    end

    render json: mask_sensitive_values(result, nil)
  end

  private

  def account_duplicate?(result, channel_id = nil)
    Channel.where(area: 'Email::Account').each do |channel|
      next if !channel.options
      next if !channel.options[:inbound]
      next if !channel.options[:inbound][:adapter]
      next if channel.options[:inbound][:adapter] != result[:setting][:inbound][:adapter]
      next if channel.options[:inbound][:options][:host] != result[:setting][:inbound][:options][:host]
      next if channel.options[:inbound][:options][:user] != result[:setting][:inbound][:options][:user]
      next if channel.options[:inbound][:options][:folder].to_s != result[:setting][:inbound][:options][:folder].to_s
      next if channel.id.to_s == channel_id.to_s

      render json: {
        result:  'duplicate',
        message: __('Account already exists!'),
      }
      return true
    end
    false
  end

  def check_online_service
    return true if !Setting.get('system_online_service')

    raise Exceptions::Forbidden
  end

  def check_access(id = nil)
    if !id
      id = params[:id]
    end
    return true if !Setting.get('system_online_service')

    channel = Channel.find(id)
    return true if channel.preferences && !channel.preferences[:online_service_disable]

    raise Exceptions::Forbidden
  end

  def handle_group_email_address(channel)
    return if !handle_group_email_address?

    if params[:group_email_address_id]
      email_address = EmailAddress.find(params[:group_email_address_id])
    end

    Service::Channel::Email::UpdateDestinationGroupEmail.execute(
      group:         Group.find(params[:group_id]),
      channel:       channel,
      email_address:,
    )
  end

  def handle_group_email_address?
    ActiveModel::Type::Boolean.new.cast params[:group_email_address]
  end
end

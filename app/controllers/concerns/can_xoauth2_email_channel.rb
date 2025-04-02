# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module CanXoauth2EmailChannel
  extend ActiveSupport::Concern

  def area
    raise NotImplementedError
  end

  def external_credential_name
    raise NotImplementedError
  end

  def index
    system_online_service = Setting.get('system_online_service')

    assets = {}
    external_credential_ids = []
    ExternalCredential.where(name: external_credential_name).each do |external_credential|
      assets = external_credential.assets(assets)
      external_credential_ids.push external_credential.id
    end

    channel_ids = []
    Channel.where(area:).reorder(:id).each do |channel|
      assets = channel.assets(assets)
      channel_ids.push channel.id
    end

    not_used_email_address_ids = []
    EmailAddress.find_each do |email_address|
      next if system_online_service && email_address.preferences && email_address.preferences['online_service_disable']

      assets = email_address.assets(assets)
      if !email_address.channel_id || !email_address.active || !Channel.exists?(email_address.channel_id)
        not_used_email_address_ids.push email_address.id
      end
    end

    render json: {
      assets:                     assets,
      not_used_email_address_ids: not_used_email_address_ids,
      channel_ids:                channel_ids,
      external_credential_ids:    external_credential_ids,
      callback_url:               ExternalCredential.callback_url(external_credential_name),
    }
  end

  def group
    channel = Channel.find_by(id: params[:id], area:)
    channel.group_id = params[:group_id]
    channel.save!

    handle_group_email_address(channel)

    render json: {}
  end

  def inbound
    channel = Channel.find_by(id: params[:id], area:)

    channel.refresh_xoauth2!(force: true)

    inbound_prepare_channel(channel)

    result = EmailHelper::Probe.inbound(channel.options[:inbound])
    raise Exceptions::UnprocessableEntity, (result[:message_human] || result[:message]) if result[:result] == 'invalid'

    render json: result
  end

  def verify
    channel = Channel.find_by(id: params[:id], area:)

    verify_prepare_channel(channel)

    channel.save!

    handle_group_email_address(channel)

    render json: {}
  end

  private

  def inbound_prepare_channel(channel)
    channel.group_id = params[:group_id] if params[:group_id].present?
    channel.active   = params[:active] if params.key?(:active)

    channel.options[:inbound] ||= {}
    channel.options[:inbound][:options] ||= {}

    %w[folder folder_id keep_on_server].each do |key|
      next if params.dig(:options, key).nil?

      channel.options[:inbound][:options][key] = params[:options][key]
    end
  end

  def verify_prepare_channel(channel)
    inbound_prepare_channel(channel)

    %w[archive archive_before archive_state_id].each do |key|
      next if params.dig(:options, key).nil?

      channel.options[:inbound][:options][key] = params[:options][key]
    end

    channel.status_in    = 'ok'
    channel.status_out   = 'ok'
    channel.last_log_in  = nil
    channel.last_log_out = nil
  end

  def handle_group_email_address(channel)
    return if !handle_group_email_address?

    if params[:group_email_address_id]
      email_address = EmailAddress.find(params[:group_email_address_id])
    end

    Service::Channel::Email::UpdateDestinationGroupEmail.new(
      group:         Group.find(params[:group_id]),
      channel:       channel,
      email_address:,
    ).execute
  end

  def handle_group_email_address?
    ActiveModel::Type::Boolean.new.cast params[:group_email_address]
  end
end

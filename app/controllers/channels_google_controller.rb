# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ChannelsGoogleController < ApplicationController
  prepend_before_action -> { authentication_check && authorize! }

  def index
    system_online_service = Setting.get('system_online_service')

    assets = {}
    external_credential_ids = []
    ExternalCredential.where(name: 'google').each do |external_credential|
      assets = external_credential.assets(assets)
      external_credential_ids.push external_credential.id
    end

    channel_ids = []
    Channel.where(area: 'Google::Account').order(:id).each do |channel|
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
      callback_url:               ExternalCredential.callback_url('google'),
    }
  end

  def enable
    channel = Channel.find_by(id: params[:id], area: 'Google::Account')
    channel.active = true
    channel.save!
    render json: {}
  end

  def disable
    channel = Channel.find_by(id: params[:id], area: 'Google::Account')
    channel.active = false
    channel.save!
    render json: {}
  end

  def destroy
    channel = Channel.find_by(id: params[:id], area: 'Google::Account')
    email   = EmailAddress.find_by(channel_id: channel.id)
    email.destroy!
    channel.destroy!
    render json: {}
  end

  def group
    channel = Channel.find_by(id: params[:id], area: 'Google::Account')
    channel.group_id = params[:group_id]
    channel.save!
    render json: {}
  end

  def inbound
    channel = Channel.find_by(id: params[:id], area: 'Google::Account')
    %w[folder keep_on_server].each do |key|
      channel.options[:inbound][:options][key] = params[:options][key]
    end

    channel.refresh_xoauth2!(force: true)

    result = EmailHelper::Probe.inbound(channel.options[:inbound])
    raise Exceptions::UnprocessableEntity, ( result[:message_human] || result[:message] ) if result[:result] == 'invalid'

    channel.status_in    = 'ok'
    channel.status_out   = 'ok'
    channel.last_log_in  = nil
    channel.last_log_out = nil
    if params.key?(:active)
      channel.active = params[:active]
    end

    channel.save!

    render json: {}
  end

  def rollback_migration
    channel = Channel.find_by!(id: params[:id], area: 'Google::Account')
    raise 'Failed to find backup on channel!' if !channel.options[:backup_imap_classic]

    channel.update!(channel.options[:backup_imap_classic][:attributes])
    render json: {}
  end

end

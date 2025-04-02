# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ChannelsMicrosoft365Controller < ApplicationController
  include CanXoauth2EmailChannel

  prepend_before_action :authenticate_and_authorize!

  def area
    'Microsoft365::Account'.freeze
  end

  def external_credential_name
    'microsoft365'.freeze
  end

  def enable
    channel = Channel.find_by(id: params[:id], area: 'Microsoft365::Account')
    channel.active = true
    channel.save!
    render json: {}
  end

  def disable
    channel = Channel.find_by(id: params[:id], area: 'Microsoft365::Account')
    channel.active = false
    channel.save!
    render json: {}
  end

  def destroy
    channel = Channel.find_by(id: params[:id], area: 'Microsoft365::Account')
    email   = EmailAddress.find_by(channel_id: channel.id)
    email&.destroy!
    channel.destroy!
    render json: {}
  end

  def rollback_migration
    channel = Channel.find_by(id: params[:id], area:)
    raise __('Failed to find backup on channel!') if !channel.options[:backup_imap_classic]

    channel.update!(channel.options[:backup_imap_classic][:attributes])
    render json: {}
  end
end

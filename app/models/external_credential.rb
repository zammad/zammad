# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ExternalCredential < ApplicationModel
  include ApplicationLib

  validates :name, presence: true
  store     :credentials

  after_update_commit :update_client_secret

  def self.app_verify(params)
    backend = load_backend(params[:provider])
    backend.app_verify(params)
  end

  def self.request_account_to_link(provider, params = {})
    backend = load_backend(provider)
    backend.request_account_to_link(params)
  end

  def self.link_account(provider, request_token, params)
    backend = load_backend(provider)
    backend.link_account(request_token, params)
  end

  def self.callback_url(provider)
    "#{Setting.get('http_type')}://#{Setting.get('fqdn')}#{Rails.configuration.api_path}/external_credentials/#{provider}/callback"
  end

  def self.app_url(provider, channel_id)
    "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#channels/#{provider}/#{channel_id}"
  end

  def self.refresh_token(provider, params)
    backend = ExternalCredential.load_backend(provider)
    backend.refresh_token(params)
  end

  def self.load_backend(provider)
    "ExternalCredential::#{provider.camelcase}".constantize
  end

  private

  def update_client_secret
    return if !saved_change_to_credentials?

    previous_client_secret = saved_changes['credentials'].first['client_secret']
    current_client_secret = saved_changes['credentials'].last['client_secret']
    return if previous_client_secret.blank? || current_client_secret.blank?
    return if previous_client_secret == current_client_secret

    backend = ExternalCredential.load_backend(name)
    return if !backend.respond_to?(:update_client_secret)

    backend.update_client_secret(previous_client_secret, current_client_secret)
  end

end

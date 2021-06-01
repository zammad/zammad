# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ExternalCredential < ApplicationModel
  include ApplicationLib

  validates :name, presence: true
  store     :credentials

  def self.app_verify(params)
    backend = load_backend(params[:provider])
    backend.app_verify(params)
  end

  def self.request_account_to_link(provider)
    backend = load_backend(provider)
    backend.request_account_to_link
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
    adapter = "ExternalCredential::#{provider.camelcase}"
    require_dependency adapter.to_filename.to_s
    adapter.constantize
  end

end

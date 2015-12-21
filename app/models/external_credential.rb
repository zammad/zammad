class ExternalCredential < ApplicationModel
  include ApplicationLib

  validates :name, presence: true
  store     :credentials

  def self.app_verify(params)
    backend = load_backend(params[:provider])
    backend.app_verify(params)
  end

  def self.request_account_to_link(provider, callback)
    backend = load_backend(provider)
    backend.request_account_to_link(callback)
  end

  def self.link_account(provider, request_token, params)
    backend = load_backend(provider)
    backend.link_account(request_token, params)
  end

  def self.load_backend(provider)
    adapter = "ExternalCredential::#{provider.camelcase}"
    require "#{adapter.to_filename}"
    load_adapter(adapter)
  end

end

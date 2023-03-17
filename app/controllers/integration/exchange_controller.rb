# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Integration::ExchangeController < ApplicationController
  include Integration::ImportJobBase

  prepend_before_action { authentication_check && authorize! }

  def index
    assets = {}
    external_credential_ids = []
    ExternalCredential.where(name: 'exchange').each do |external_credential|
      assets = external_credential.assets(assets)
      external_credential_ids.push external_credential.id
    end

    render json: {
      assets:                  assets,
      oauth:                   Setting.get('exchange_oauth'),
      external_credential_ids: external_credential_ids,
      callback_url:            ExternalCredential.callback_url('exchange'),
    }
  end

  def destroy_oauth
    Setting.set('exchange_oauth', {})
    render json: {}
  end

  def autodiscover
    if params[:authentication_method].present? && params[:authentication_method] == 'oauth'
      render json: {}
      return
    end

    answer_with do
      autodiscover_basic_auth_check
    end
  end

  def folders
    answer_with do
      Sequencer.process('Import::Exchange::AvailableFolders',
                        parameters: { ews_config: ews_config })
               .tap do |res|
                 raise __('No folders were found for the given user credentials.') if res[:folders].blank?
               end
    end
  end

  def mapping
    answer_with do
      raise __('Please select at least one folder.') if params[:folders].blank?

      Sequencer.process('Import::Exchange::AttributesExamples',
                        parameters: { ews_folder_ids: params[:folders],
                                      ews_config:     ews_config })
               .tap do |res|
                 raise __('No entries were found in the selected folder(s).') if res[:attributes].blank?
               end
    end
  end

  private

  def payload_dry_run
    {
      ews_attributes: params[:attributes].permit!.to_h,
      ews_folder_ids: params[:folders],
      ews_config:     ews_config,
      params:         params,
    }
  end

  def ews_config
    {
      disable_ssl_verify: params[:disable_ssl_verify],
      endpoint:           params[:endpoint],
      user:               params[:user],
      password:           params[:password],
      auth_type:          params[:auth_type],
      access_token:       Setting.get('exchange_oauth')[:access_token],
    }
  end

  def autodiscover_basic_auth_check
    require 'autodiscover' # Only load this gem when it is really used.
    client = Autodiscover::Client.new(
      email:    params[:user],
      password: params[:password],
    )

    if params[:disable_ssl_verify]
      client.http.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    begin
      { endpoint: client.autodiscover&.ews_url }
    rescue Errno::EADDRNOTAVAIL
      {}
    end
  end
end

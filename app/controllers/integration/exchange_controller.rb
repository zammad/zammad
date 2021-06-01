# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Integration::ExchangeController < ApplicationController
  include Integration::ImportJobBase

  prepend_before_action { authentication_check && authorize! }

  def autodiscover
    answer_with do
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

  def folders
    answer_with do
      Sequencer.process('Import::Exchange::AvailableFolders',
                        parameters: { ews_config: ews_config })
               .tap do |res|
                 raise 'No folders found for given user credentials.' if res[:folders].blank?
               end
    end
  end

  def mapping
    answer_with do
      raise 'Please select at least one folder.' if params[:folders].blank?

      Sequencer.process('Import::Exchange::AttributesExamples',
                        parameters: { ews_folder_ids: params[:folders],
                                      ews_config:     ews_config })
               .tap do |res|
                 raise 'No entries found in selected folder(s).' if res[:attributes].blank?
               end
    end
  end

  private

  def payload_dry_run
    {
      ews_attributes: params[:attributes].permit!.to_h,
      ews_folder_ids: params[:folders],
      ews_config:     ews_config
    }
  end

  def ews_config
    {
      disable_ssl_verify: params[:disable_ssl_verify],
      endpoint:           params[:endpoint],
      user:               params[:user],
      password:           params[:password],
    }
  end
end

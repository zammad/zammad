# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Integration::ExchangeController < ApplicationController
  include Integration::ImportJobBase

  prepend_before_action { authentication_check(permission: 'admin.integration.exchange') }

  def autodiscover
    answer_with do
      client = Autodiscover::Client.new(
        email:    params[:user],
        password: params[:password],
      )

      {
        endpoint: client.try(:autodiscover).try(:ews_url),
      }
    end
  end

  def folders
    answer_with do
      Sequencer.process('Import::Exchange::AvailableFolders',
                        parameters: {
                          ews_config: {
                            endpoint: params[:endpoint],
                            user:     params[:user],
                            password: params[:password],
                          }
                        })
    end
  end

  def mapping
    answer_with do
      raise 'Please select at least one folder.' if params[:folders].blank?

      examples = Sequencer.process('Import::Exchange::AttributesExamples',
                                   parameters: {
                                     ews_folder_ids: params[:folders],
                                     ews_config:     {
                                       endpoint: params[:endpoint],
                                       user:     params[:user],
                                       password: params[:password],
                                     }
                                   })
      examples.tap do |result|
        raise 'No entries found in selected folder(s).' if result[:attributes].blank?
      end
    end
  end

  private

  # currently a workaround till LDAP is migrated to Sequencer
  def payload_dry_run
    {
      ews_attributes: params[:attributes],
      ews_folder_ids: params[:folders],
      ews_config:     {
        endpoint: params[:endpoint],
        user:     params[:user],
        password: params[:password],
      }
    }
  end

  def payload_import
    nil
  end
end

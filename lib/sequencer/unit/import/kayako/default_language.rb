# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::DefaultLanguage < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Kayako::Requester

  provides :default_language

  def process
    state.provide(:default_language, default_language)
  end

  private

  def default_language
    settings = fetch_settings

    default_language_setting = settings.detect { |item| item['name'] == 'default_language' }

    default_language_setting['value'] || 'en-us'
  end

  def fetch_settings
    response = request(
      api_path: 'settings'
    )

    body = JSON.parse(response.body)
    body['data']
  rescue => e
    logger.error 'Error when fetching settings for default language'
    logger.error e

    nil
  end
end

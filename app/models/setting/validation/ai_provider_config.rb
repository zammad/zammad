# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Setting::Validation::AIProviderConfig < Setting::Validation::Base
  attr_reader :provider

  def initialize(record)
    super

    @provider = Setting.get('ai_provider')
  end

  def run
    return result_success if value.blank? || provider.blank?

    msg = verify_configuration
    return result_failed(msg) if !msg.nil?

    result_success
  end

  private

  def verify_configuration
    msg = required_attributes
    return msg if !msg.nil?

    accessible
  end

  def required_attributes
    case provider
    when 'ollama'
      return __('AI provider Ollama URL is not set') if value['url'].blank?
    else
      return __('AI provider token is not set') if value['token'].blank?
    end

    nil
  end

  def accessible
    provider_class = AI::Provider.by_name(provider)

    provider_class.ping!(value)

    nil
  rescue => e
    __("AI provider is not accessible: #{e.message}")
  end
end

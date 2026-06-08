# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Setting::Validation::AIProviderConfig < Setting::Validation::Base
  attr_reader :provider

  ERROR_MESSAGE_OLLAMA = __('AI provider Ollama URL is not set').freeze
  ERROR_MESSAGE_AZURE  = __('AI provider Azure configuration is incomplete').freeze
  ERROR_MESSAGE_TOKEN  = __('AI provider token is not set').freeze

  class AIProviderConfigError < StandardError; end

  def initialize(record)
    super

    @provider = value[:provider]
  end

  def run
    return result_success if value.blank?

    verify_configuration

    result_success
  rescue AIProviderConfigError => e
    result_failed(e.message)
  end

  private

  def verify_configuration
    validate_provider
    required_attributes
    accessible
  end

  def required_attributes
    case provider
    when 'ollama'
      required_attributes_ollama
    when 'azure'
      required_attributes_azure
    when 'zammad_ai'
      required_attributes_zammad
    when 'custom_open_ai'
      required_attributes_custom_open_ai
    else
      required_attributes_token
    end
  end

  def required_attributes_azure
    raise AIProviderConfigError, ERROR_MESSAGE_AZURE if %w[url_completions token].any? { |key| value[key].blank? }
  end

  def required_attributes_ollama
    raise AIProviderConfigError, ERROR_MESSAGE_OLLAMA if value['url'].blank?
  end

  def required_attributes_token
    raise AIProviderConfigError, ERROR_MESSAGE_TOKEN if value['token'].blank?
  end

  def required_attributes_zammad
    return if Setting.get('system_online_service')

    required_attributes_token
  end

  def required_attributes_custom_open_ai
    raise AIProviderConfigError, __('AI provider URL is not set') if value['url'].blank?
    raise AIProviderConfigError, __('AI Provider Model is not set') if value['model'].blank?
  end

  def validate_provider
    raise AIProviderConfigError, __('AI provider is missing') if provider.blank?
    raise AIProviderConfigError, __('AI provider is not supported') if !AI::Provider.by_name(provider)
  end

  def accessible
    provider_class = AI::Provider.by_name(provider)

    provider_class.ping!(value)
    check_temperature_support!(provider_class)
  rescue AIProviderConfigError
    raise
  rescue => e
    raise AIProviderConfigError, __("AI provider is not accessible: #{e.message}")
  end

  def check_temperature_support!(provider_class)
    value['model_temperature_support'] = provider_class.check_temperature_support!(value)
  end
end

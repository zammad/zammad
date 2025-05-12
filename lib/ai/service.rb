# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Service
  include Mixin::RequiredSubPaths

  PROMPT_PATH_STRING = Rails.root.join('lib/ai/service/prompts/%{type}/%{service}.txt.erb').to_s.freeze

  attr_reader :current_user, :context_data, :ignore_cache, :locale

  def self.list
    @list ||= descendants.sort_by(&:name)
  end

  def initialize(context_data:, current_user: nil, prompt_system: nil, prompt_user: nil, ignore_cache: false, locale: nil)
    @context_data = context_data
    @current_user = current_user
    @prompt_system = prompt_system
    @prompt_user = prompt_user
    @ignore_cache = ignore_cache
    @locale = locale || @current_user&.locale || Locale.default
  end

  def self.name_service
    name.sub('AI::Service::', '')
  end

  def execute
    if cachable? && !ignore_cache
      result = from_cache

      return result if result
    end

    current_prompt_system = @prompt_system || render_prompt(prompt_system)
    current_prompt_user   = @prompt_user   || render_prompt(prompt_user)

    result = provider.ask(prompt_system: current_prompt_system, prompt_user: current_prompt_user)

    save_cache(result) if cachable?

    result
  end

  private

  def provider
    @provider ||= AI::Provider.by_name(provider_name).new(
      options: options.merge({ service_name: self.class.name_service, json_response: json_response? })
    )
  end

  def provider_name
    @provider_name ||= Setting.get('ai_provider')
  end

  def from_cache
    cache = Rails.cache.read(cache_key)
    return cache if cache.present?

    nil
  end

  def save_cache(result)
    # TODO: time per service?
    expires_in = result.blank? ? 1.minute : 14.days

    Rails.cache.write(cache_key, result, { expires_in: })
  end

  def cachable?
    false
  end

  def cache_key
    nil
  end

  def json_response?
    true
  end

  def options
    {}
  end

  def prompt_file_name
    @prompt_file_name ||= self.class.name_service.underscore
  end

  def prompt_system
    File.read(format(PROMPT_PATH_STRING, type: 'system', service: prompt_file_name))
  end

  def prompt_user
    File.read(format(PROMPT_PATH_STRING, type: 'user', service: prompt_file_name))
  end

  def render_prompt(prompt_template)
    ERB.new(prompt_template.to_s).result(binding)
  end
end

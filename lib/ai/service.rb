# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Service
  include Mixin::RequiredSubPaths

  PROMPT_PATH_STRING = Rails.root.join('lib/ai/service/prompts/%{type}/%{service}.txt.erb').to_s.freeze

  attr_reader :current_user, :context_data, :locale, :persistence_strategy, :additional_options, :regeneration_of

  Result = Struct.new(:content, :stored_result, :fresh, :ai_analytics_run, keyword_init: true)

  def self.list
    @list ||= descendants.sort_by(&:name)
  end

  # @param persistence_strategy [Symbol, NilClass] :stored_or_request, :stored_only, :request_only.
  def initialize(context_data:, current_user: nil, persistence_strategy: :stored_or_request, prompt_system: nil, prompt_user: nil, locale: nil, regeneration_of: nil, additional_options: {})
    @context_data         = context_data
    @current_user         = current_user
    @given_prompt_system  = prompt_system
    @given_prompt_user    = prompt_user
    @persistence_strategy = persistence_strategy
    @additional_options   = additional_options
    @regeneration_of      = regeneration_of
    @locale               = Locale.find_by(locale: locale || @current_user&.locale || Locale.default)
  end

  def self.name_service
    name.sub('AI::Service::', '')
  end

  # @return [Result] result of the AI service
  def execute
    case persistence_strategy
    when :stored_or_request
      fetch_stored || request_fresh
    when :stored_only
      fetch_stored
    when :request_only
      request_fresh
    end
  end

  def self.lookup_attributes(_context_data, _locale)
    raise 'not implemented'
  end

  def self.lookup_version(_context_data, _locale)
    raise 'not implemented'
  end

  private

  def fetch_stored
    return if regeneration_of
    return if !persistable?

    stored_result = AI::StoredResult.find_by(lookup_attributes_with_version)

    return if !stored_result

    Result.new(
      content:          stored_result.content,
      stored_result:,
      ai_analytics_run: stored_result.ai_analytics_run,
      fresh:            false
    )
  end

  def request_fresh
    response = post_transform_result(ask_provider)

    if response.nil?
      save_analytics_run if analytics?
      return
    end

    ai_analytics_run = save_analytics_run(result: response) if analytics?
    stored_result    = save_result(response, ai_analytics_run:) if persistable?

    Result.new(content: response, stored_result:, ai_analytics_run:, fresh: true)
  rescue => e
    save_analytics_run(error: e) if analytics?
    raise e
  end

  def prompt_system
    @prompt_system ||= @given_prompt_system || render_prompt(prompt_system_from_file)
  end

  def prompt_user
    @prompt_user ||= begin
      prompt = @given_prompt_user || render_prompt(prompt_user_from_file)

      transform_user_prompt(prompt)
    end
  end

  def ask_provider
    provider.ask(prompt_system:, prompt_user:)
  end

  def provider
    @provider ||= AI::Provider.by_name(provider_name).new(
      options: options.merge({
                               service_name:  self.class.name_service,
                               json_response: json_response?,
                               model:         additional_options[:model],
                             })
    )
  end

  def provider_name
    @provider_name ||= Setting.get('ai_provider_config')&.dig(:provider)
  end

  def save_result(result, ai_analytics_run:)
    AI::StoredResult
      .find_or_initialize_by(lookup_attributes)
      .tap do |record|
        record.update!(
          version:          lookup_version,
          metadata:         provider.metadata,
          content:          result,
          ai_analytics_run:
        )
      end
  end

  def save_analytics_run(result: nil, error: nil)
    if error
      error_metadata = {
        error_message: error.message,
        error_class:   error.class.name
      }
    end

    AI::Analytics::Run.create(
      **lookup_attributes_with_version,
      context:         { metadata: provider.metadata },
      content:         result || {},
      payload:         { prompt_system:, prompt_user: },
      error:           error_metadata || {},
      ai_service_name: self.class.name_service,
      regeneration_of:
    )
  end

  def persistable?
    false
  end

  def analytics?
    false
  end

  def lookup_attributes_with_version
    lookup_attributes.merge(version: lookup_version)
  end

  def lookup_attributes
    self.class.lookup_attributes(context_data, locale)
  end

  def lookup_version
    self.class.lookup_version(context_data, locale)
  end

  def post_transform_result(result)
    result
  end

  def transform_user_prompt(prompt)
    prompt
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

  def prompt_system_from_file
    File.read(format(PROMPT_PATH_STRING, type: 'system', service: prompt_file_name))
  end

  def prompt_user_from_file
    File.read(format(PROMPT_PATH_STRING, type: 'user', service: prompt_file_name))
  end

  def render_prompt(prompt_template)
    ERB.new(prompt_template.to_s, trim_mode: '-').result(binding)
  end
end

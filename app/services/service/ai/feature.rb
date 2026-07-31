# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Base class of the AI feature services (ticket summary, text tools, ...): renders the
# feature's prompts, runs them against the provider connection resolved for the feature and
# handles stored results and analytics. Concrete features are registered by subclassing.
class Service::AI::Feature < Service::Base
  include Mixin::RequiredSubPaths

  PROMPT_PATH_STRING = Rails.root.join('app/services/service/ai/feature/prompts/%{type}/%{service}.txt.erb').to_s.freeze

  attr_reader :context_data, :locale, :persistence_strategy, :additional_options, :regeneration_of

  Result = Struct.new(:content, :stored_result, :fresh, :ai_analytics_run)

  class InvalidResultKeysError < StandardError
    def initialize
      super(__('AI service result is missing expected keys'))
    end
  end

  def self.list
    @list ||= descendants.sort_by(&:name)
  end

  # Stable identifier for this feature; doubles as the provider-routing key
  # (AI::ProviderConnection.for_chat). nil = the `default` connection.
  def self.identifier
    nil
  end

  # The routable identifiers — the source of truth for AI::FeatureProvider validation.
  def self.identifiers
    list.filter_map(&:identifier).uniq
  end

  # @param persistence_strategy [Symbol, NilClass] :stored_or_request, :stored_only, :request_only.
  def initialize(context_data:, persistence_strategy: :stored_or_request, prompt_system: nil, prompt_user: nil, prompt_image: nil, locale: nil, regeneration_of: nil, additional_options: {})
    @context_data         = context_data
    @given_prompt_system  = prompt_system
    @given_prompt_user    = prompt_user
    @given_prompt_image   = prompt_image
    @persistence_strategy = persistence_strategy
    @additional_options   = additional_options
    @regeneration_of      = regeneration_of
    @locale               = Locale.find_by(locale: locale || current_user&.locale || Locale.default)
  end

  def self.name_service
    name.demodulize
  end

  # @return [Result] result of the AI feature service
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
    result = ask_provider

    validate_result!(result)

    response = post_transform_result(result)

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

  def prompt_image
    @given_prompt_image
  end

  def ask_provider
    connection.record_call do
      provider.ask(prompt_system:, prompt_user:, prompt_image:)
    end
  end

  # The provider connection serving this feature; also records the call outcome as its
  # stored health status (see #ask_provider).
  def connection
    @connection ||= AI::ProviderConnection.for_chat(self.class.identifier) ||
                    raise(__('AI provider is not configured.'))
  end

  def provider
    @provider ||= connection.provider_instance(options: provider_options) ||
                  raise(__('AI provider is not configured.'))
  end

  # Model precedence: caller options > feature routing options > connection config.
  def provider_options
    AI::FeatureProvider.options_for(self.class.identifier).merge(
      options.merge(
        service_name:  self.class.name_service,
        json_response: json_response?,
        model:         additional_options[:model],
      ).compact
    )
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
      payload:         { prompt_system:, prompt_user:, prompt_image: },
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

  def validate_result!(_result); end

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
  rescue Errno::ENOENT
    ''
  end

  def prompt_user_from_file
    File.read(format(PROMPT_PATH_STRING, type: 'user', service: prompt_file_name))
  end

  def render_prompt(prompt_template)
    ERB.new(prompt_template.to_s, trim_mode: '-').result(binding)
  end

  # Prompt templates wrap ticket content in an XML-like structure; escape interpolated
  # values so the content cannot break or fake that structure.
  def xml_text(value)
    value.to_s.encode(xml: :text)
  end

  # CDATA keeps the content readable for the model (no entity escaping); splitting ']]>'
  # prevents breaking out of the section.
  def cdata(value)
    "<![CDATA[#{value.to_s.gsub(']]>', ']]]]><![CDATA[>')}]]>"
  end
end

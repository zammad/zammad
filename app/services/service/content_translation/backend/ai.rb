# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Translation through the AI provider. Everything the LLM path needs - prompts, stored results,
# analytics - lives in the AI feature; this class only maps it onto backend-neutral data.
class Service::ContentTranslation::Backend::AI < Service::ContentTranslation::Backend::Base
  attr_reader :object, :content, :html, :locale, :persistence_strategy, :regeneration_of

  # The AI provider is a feature switch of its own, so only this backend asks about it; a service
  # configured elsewhere answers for itself.
  def self.ensure_enabled!
    Service::CheckFeatureEnabled.execute(name: 'ai_provider', custom_error_message: __('AI provider is not configured.'))
  end

  # An LLM call takes seconds, so a caller that can wait for a subscription should not block on it.
  def self.background?
    true
  end

  # Names the producing service for the caller, which renders it as the translation's origin -
  # so it must not follow a class rename, and is therefore not derived from the class name. It is
  # stored with every translation this backend produces.
  def self.backend_name
    'ai'
  end

  def initialize(object:, content:, html:, locale:, persistence_strategy: :stored_or_request, regeneration_of: nil)
    @object               = object
    @content              = content
    @html                 = html
    @locale               = locale
    @persistence_strategy = persistence_strategy
    @regeneration_of      = regeneration_of
  end

  # @return [Hash, NilClass] `content`, `backend`, `fresh` and `analytics_run`; nil without a
  #   translation. `backend` comes out of the store, not from this class: a stored translation is
  #   reused across services, so the one that answers is not necessarily the one that made it.
  def execute
    result = Service::AI::Feature::Translate.execute(
      locale:               locale.locale,
      context_data:         { object:, body: content, html:, backend: backend_name },
      persistence_strategy:,
      regeneration_of:,
    )

    return if result.nil?

    {
      content:       result.content,
      backend:       result.stored_result&.metadata&.dig('backend') || backend_name,
      fresh:         result.fresh,
      analytics_run: result.ai_analytics_run,
    }
  end
end

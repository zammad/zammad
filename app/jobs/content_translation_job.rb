# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Runs a content translation in the background, because the translation service takes seconds and
# no request should wait for it. It knows nothing about what is translated: the service that
# enqueued the job comes along as an argument and names the subscription its result is published to.
class ContentTranslationJob < AIJob
  include HasActiveJobLock

  # One translation of an object into a locale at a time; a second request while one runs is
  # answered by the same subscription event. This is also the guard against two concurrent first
  # requests hitting the unique index of the stored result.
  EXISTING_ACTIVE_JOB_LOCK_BEHAVIOUR = :dismiss_running

  def lock_key
    "#{self.class.name}/#{arguments[0].class.name}/#{arguments[0].id}/#{arguments[1]}"
  end

  # No current user: nothing a translation writes is attributed to one, and an automatic
  # translation has no user to attribute it to. Per-user analytics is recorded by the caller.
  def perform(object, target_locale, service:, regeneration_of: nil)
    # Resolved outside the error handling below on purpose: an unknown service is a programming
    # error, not something to publish to a client.
    translate_and_publish(service.constantize, object, target_locale, regeneration_of:)
  end

  private

  def translate_and_publish(service_class, object, target_locale, regeneration_of:)
    # Forced, because whether the content is already in the target language is decided before a job
    # is enqueued - anything that reaches the job is meant to be translated. And not in the
    # background, because this is the background.
    translation = service_class.execute(object:, target_locale:, force: true, background: false, regeneration_of:)

    service_class.subscription.trigger_for(object, target_locale, subscription_data(translation))
  rescue => e
    Rails.logger.error "ContentTranslationJob failed for #{object.class.name}/#{object.id}: #{e.message}\n#{e.backtrace.join("\n")}"

    service_class.subscription.trigger_for(object, target_locale, { error: { message: e.message, exception: e.class.name } })
  end

  def subscription_data(translation)
    return {} if translation.nil?

    {
      translation:         {
        content:    translation.content,
        backend:    translation.backend,
        translated: translation.translated,
      },
      ai_analytics_run_id: translation.analytics_run&.id,
    }.compact
  end
end

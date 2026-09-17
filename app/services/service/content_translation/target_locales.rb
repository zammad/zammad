# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The locales content can be translated into: the active Zammad locales, narrowed down to those the
# configured translation service supports.
class Service::ContentTranslation::TargetLocales < Service::Base
  # @return [Array<Locale>] sorted by name
  def execute
    Service::CheckFeatureEnabled.execute(name: 'content_translation_service', custom_error_message: __('No translation service is configured.'))

    # A service that cannot translate right now has no target locales to offer - the AI backend,
    # for one, needs a configured AI provider.
    backend_class.ensure_enabled!

    backend_class.supported_locales(Locale.where(active: true).reorder(:name).to_a)
  end

  private

  def backend_class
    Service::ContentTranslation::Backend.configured || raise(Service::ContentTranslation::Base::UnknownBackendError)
  end
end

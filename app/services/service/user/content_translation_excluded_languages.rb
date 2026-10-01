# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Remembers the languages the current user reads in the original: translating a whole ticket
#   leaves articles in them untranslated. Each entry is a language as returned by
#   Locale.language_of, never a regional locale.
class Service::User::ContentTranslationExcludedLanguages < Service::Base
  requires_current_user!

  attr_reader :languages

  def initialize(languages:)
    @languages = languages
  end

  def execute
    # Only translating a whole ticket reads the list, so it follows the same gate.
    Service::ContentTranslation::TicketArticle::CheckAutoAllowed.execute(user: current_user)
    ensure_system_languages!

    current_user.preferences['content_translation_excluded_languages'] = languages
    current_user.save!
  end

  private

  def ensure_system_languages!
    system_languages = Locale.where(active: true).pluck(:locale).map { Locale.language_of(it) }
    return if (languages - system_languages).empty?

    raise ActiveRecord::RecordNotFound, __('Language could not be found.')
  end
end

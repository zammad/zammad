# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Remembers the one language the current user translates content into. It is a personal
#   preference: whatever picks it - today the ticket view's switcher - changes it everywhere.
class Service::User::ContentTranslationTargetLocale < Service::Base
  requires_current_user!

  attr_reader :target_locale

  def initialize(target_locale:)
    @target_locale = target_locale
  end

  def execute
    if !Locale.exists?(locale: target_locale, active: true)
      raise ActiveRecord::RecordNotFound, __('Locale could not be found.')
    end

    current_user.preferences['content_translation_target_locale'] = target_locale
    current_user.save!
  end
end

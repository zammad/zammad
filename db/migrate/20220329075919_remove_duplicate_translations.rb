# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class RemoveDuplicateTranslations < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # For some obsure reason, in legacy systems there was a chance that Translation records with the same locale and source
    #   appeared multiple times.

    Locale.all.each do |locale|

      # Remove duplicates of all synchronized strings first.
      cleanup_duplicates_of_synchronized(locale)

      # Remove other duplicates of unsynchronized strings as well.
      cleanup_duplicates_of_unsynchronized(locale)
    end
  end

  def cleanup_duplicates_of_synchronized(locale)
    unsync_translations = Translation.where(locale: locale.locale, is_synchronized_from_codebase: false).all
    Translation.where(locale: locale.locale, is_synchronized_from_codebase: true).all.each do |t|
      unsync_translations.select { |unsync_t| unsync_t.source == t.source }.each(&:destroy)
    end
  end

  def cleanup_duplicates_of_unsynchronized(locale)
    unsync_translations = Translation.where(locale: locale.locale, is_synchronized_from_codebase: false).order(:id).all
    unsync_translations.each do |t|
      next if t.destroyed?

      unsync_translations.select { |check_t| check_t.id > t.id && check_t.source == t.source && !check_t.destroyed? }.each(&:destroy)
    end
  end
end

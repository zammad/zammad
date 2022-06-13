# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Translation::SynchronizesFromPo
  extend ActiveSupport::Concern

  TRANSLATION_FILE_STRUCT = Struct.new(:translation, :translation_file, keyword_init: true).freeze

  class_methods do # rubocop:disable Metrics/BlockLength

    def sync
      Locale.to_sync.each do |locale|
        ActiveRecord::Base.transaction do
          sync_locale_from_po locale.locale
        end
      end
    end

    def sync_locale_from_po(locale) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      previous_translation_map = Translation.where(locale: locale).index_by(&:source)

      previous_unmodified_translations = Translation.where(locale: locale, is_synchronized_from_codebase: true).select { |t| t.target.eql?(t.target_initial) }
      updated_translation_ids = Set[]
      importable_translations = []

      strings_for_locale(locale).each_pair do |source, entry| # rubocop:disable Metrics/BlockLength

        if source.length > 3000 || entry.translation.length > 3000
          Rails.logger.error "Cannot import translation for locale #{locale} because it exceeds maximum string length of 3000: source: '#{source}', translation: '#{entry.translation}'"
          next
        end

        t = previous_translation_map[source]
        # New string
        if !t
          importable_translations << Translation.new(
            locale:                             locale,
            source:                             source,
            target:                             entry.translation,
            target_initial:                     entry.translation,
            is_synchronized_from_codebase:      true,
            synchronized_from_translation_file: entry.translation_file,
            created_by_id:                      1,
            updated_by_id:                      1
          )
          next
        end

        # Existing string
        # Only change the target if it was not modified by the user
        t.target = entry.translation if t.target.eql? t.target_initial

        t.is_synchronized_from_codebase      = true
        t.synchronized_from_translation_file = entry.translation_file
        t.target_initial                     = entry.translation

        if t.changed.present?
          t.updated_by_id = 1
          t.save!
        end
        updated_translation_ids.add t.id
      end

      Translation.bulk_import importable_translations
      # Remove any unmodified & synchronized strings that are not present in the data any more.
      previous_unmodified_translations.reject { |t| updated_translation_ids.member? t.id }.each(&:destroy!)
      true
    end

    def strings_for_locale(locale) # rubocop:disable Metrics/AbcSize
      result = {}
      po_files_for_locale(locale).each do |file|
        require 'poparser' # Only load when it is actually used
        PoParser.parse_file(Rails.root.join(file)).entries.each do |entry|

          source = unescape_po(entry.msgid.to_s)

          # Make sure to ignore fuzzy entries.
          translation = entry.translated? ? unescape_po(entry.msgstr.to_s) : ''

          # For 'en-*' locales, treat source as translation as well, to indicate that nothing is missing.
          translation = source if translation.empty? && locale.start_with?('en')
          result[source] = TRANSLATION_FILE_STRUCT.new(translation: translation, translation_file: file)
        end
      end
      result
    end

    def unescape_po(string)
      string.gsub(%r{\\n}, "\n").gsub(%r{\\"}, '"').gsub(%r{\\\\}, '\\')
    end

    # Returns all po files for a locale with zammad.*.po as first entry,
    #   followed by all other files in alphabetical order
    # For en-us, i18n/zammad.pot will be returned instead.
    def po_files_for_locale(locale)
      return ['i18n/zammad.pot'] if locale.eql? 'en-us'

      files = Dir.glob "i18n/*.#{locale}.po", base: Rails.root
      if files.exclude?("i18n/zammad.#{locale}.po")
        Rails.logger.error "No translation found for locale '#{locale}'."
        return []
      end

      [
        files.delete("i18n/zammad.#{locale}.po"),
        *files.sort
      ]
    end
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Translation::SynchronizesFromPo
  extend ActiveSupport::Concern

  # Represents an entry to import to the Translation table.
  class TranslationEntry
    attr_reader :source, :translation_file, :skip_sync
    attr_accessor :translation

    def self.create(locale, file, entry) # rubocop:disable Metrics/AbcSize
      source = unescape_po(entry.msgid.to_s)

      # Make sure to ignore fuzzy entries.
      translation = entry.translated? ? unescape_po(entry.msgstr.to_s) : ''

      # For 'en-*' locales, treat source as translation as well, to indicate that nothing is missing.
      translation = source if translation.empty? && locale.start_with?('en')

      # Some strings are not needed in the database, because changes will take no effect and
      #   also keep storage small.
      skip_sync = entry.reference.present? && [entry.reference].flatten.all? do |ref|
        # Ignore strings that come only from the chat, form and view_template extractors.
        # We tried avoiding this by using gettext flags in the pot file, but they don't propagate
        #   correctly to the translation files.
        ref.to_s.start_with?(%r{public/assets/(?:chat|form)/|app/views/(?:mailer|slack)/})
      end
      new(source: source, translation: translation, translation_file: file, skip_sync: skip_sync)
    end

    def self.unescape_po(string)
      string.gsub(%r{\\n}, "\n").gsub(%r{\\"}, '"').gsub(%r{\\\\}, '\\')
    end

    def skip_sync?
      @skip_sync
    end

    private

    def initialize(source:, translation:, translation_file:, skip_sync:)
      @source = source
      @translation = translation
      @translation_file = translation_file
      @skip_sync = skip_sync
    end
  end

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

        next if entry.skip_sync?

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

    def cached_strings_for_locale(locale)
      @cached_strings_for_locale ||= {}
      @cached_strings_for_locale[locale] ||= strings_for_locale(locale).freeze
    end

    def strings_for_locale(locale) # rubocop:disable Metrics/AbcSize
      result = {}
      po_files_for_locale(locale).each do |file|
        require 'poparser' # Only load when it is actually used
        PoParser.parse_file(Rails.root.join(file)).entries.each do |entry|

          TranslationEntry.create(locale, file, entry).tap do |translation_entry|

            # In case of Serbian Latin locale, transliterate the translation string to latin alphabet on-the-fly.
            if locale == 'sr-latn-rs'
              require 'byk/safe' # Only load when it is actually used
              translation_entry.translation = Byk.to_latin(translation_entry.translation)
            end

            result[translation_entry.source] = translation_entry
          end
        end
      end
      result
    end

    # Returns all po files for a locale with zammad.*.po as first entry,
    #   followed by all other files in alphabetical order
    # For en-us, i18n/zammad.pot will be returned instead.
    def po_files_for_locale(locale)
      return ['i18n/zammad.pot'] if locale.eql? 'en-us'

      locale_name = locale

      # In case of Serbian Latin locale, return Serbian Cyrillic po files instead.
      locale_name = 'sr-cyrl-rs' if locale_name == 'sr-latn-rs'

      files = Dir.glob "i18n/*.#{locale_name}.po", base: Rails.root
      if files.exclude?("i18n/zammad.#{locale_name}.po")
        Rails.logger.error "No translation found for locale '#{locale_name}'."
        return []
      end

      [
        files.delete("i18n/zammad.#{locale_name}.po"),
        *files.sort
      ]
    end
  end
end

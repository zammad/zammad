# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module HasTranslations # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  included do
    has_many :translations, class_name: translation_class_name,
                            inverse_of: name.demodulize.underscore,
                            dependent:  :destroy

    validate :validate_translations

    accepts_nested_attributes_for :translations

    # returns objects having a translation in the given KnowledgeBase::Locale.
    # Filters via a subquery (no joins), so it stays composable with .or.
    scope :translated_to, lambda { |kb_locale|
      where(id: translation_class.where(kb_locale: kb_locale).select(reflect_on_association(:translations).foreign_key))
    }

    # Translated to the given *system* locale — what `localed` filters by, composable with `.or`.
    #
    # Not `translated_to`'s `id IN (subquery)`: the help site asks this of one row at a time (the
    #   knowledge base, a category lookup, the breadcrumb, the adjacent-answer walk), and PostgreSQL
    #   answers that form by first hashing every translation of the locale — about 7 ms for one of
    #   10,000 categories, against 0.1 ms for a probe of the (kb_locale_id, owner id) index. The
    #   locale ids are literal (KnowledgeBase::Locale.translation_preference_ids) so that index
    #   serves the whole probe, and `OFFSET 0` keeps the planner from rewriting the EXISTS back into
    #   the hashed form, which it did on a listing of thirty.
    scope :translated_to_system_locale, lambda { |system_locale_or_id|
      where(translated_to_system_locale_sql(system_locale_or_id))
    }

    # returns objects with single translation according to given locale.
    # If no locale is given, defaults to Knowledge Base's primary locale
    scope :localed, lambda { |system_locale_or_id|
      output = eager_load(:translations).joins(translations: { kb_locale: :knowledge_base })

      if system_locale_or_id.present?
        output.where('knowledge_base_locales.system_locale_id' => system_locale_or_id)
      else
        output.where('knowledge_base_locales.system_locale_id' => -1)
      end
    }

    # Loads each record with the single translation it is *shown* under — the given locale's, then
    #   the primary one, then any — so `#translation` on it is that one, as it is after `localed`,
    #   which unlike this drops the records not translated to the locale.
    scope :with_preferred_translation, lambda { |system_locale_or_id|
      eager_load(:translations)
        .where("#{translation_class.table_name}.id = (#{preferred_translation_sql(:id, system_locale_or_id)})")
    }
  end

  def translation
    translations.first
  end

  def translation_to(kb_locale_or_id)
    translations.find_by(kb_locale_id: kb_locale_or_id)
  end

  def translation_preferred(kb_locale_or_id)
    translation_to(kb_locale_or_id) || translation_primary || translations.first
  end

  def translation_primary
    translations.joins(:kb_locale).find_by(knowledge_base_locales: { primary: true })
  end

  class_methods do # rubocop:disable Metrics/BlockLength
    def translation_class_name
      "#{name}::Translation"
    end

    def translation_class
      translation_class_name.constantize
    end

    # The check of .translated_to_system_locale as a correlated EXISTS on the row of `table_name`,
    #   for a WHERE — see there.
    def translated_to_system_locale_sql(system_locale_or_id)
      foreign_key = reflect_on_association(:translations).foreign_key

      ActiveRecord::Base.sanitize_sql_array(
        [
          <<~SQL.squish,
            EXISTS (SELECT 1 FROM #{translation_class.table_name} translations
                     WHERE translations.#{connection.quote_column_name(foreign_key)} = #{table_name}.id
                       AND translations.kb_locale_id IN (:browsed)
                     OFFSET 0)
          SQL
          { browsed: ::KnowledgeBase::Locale.translation_preference_ids(system_locale_or_id)[:browsed] },
        ]
      )
    end

    # The value of one column of the translation a record is *shown* under, as a scalar subquery
    #   usable in a WHERE or an ORDER BY: the three levels of Gql::Types::KnowledgeBase::AnswerType
    #   #preferred_translation (requested locale, then the primary locale, then any) as one
    #   preference chain — a join would drop the records without a translation in the browsed locale.
    # The preference is compared against kb_locale ids resolved once for the whole listing rather
    #   than joined per row — see KnowledgeBase::Locale.translation_preference_ids.
    def preferred_translation_sql(column, system_locale_or_id)
      foreign_key = reflect_on_association(:translations).foreign_key

      ActiveRecord::Base.sanitize_sql_array(
        [
          <<~SQL.squish,
            (SELECT translations.#{connection.quote_column_name(column)}
               FROM #{translation_class.table_name} translations
              WHERE translations.#{connection.quote_column_name(foreign_key)} = #{table_name}.id
              ORDER BY (translations.kb_locale_id IN (:browsed)) DESC, (translations.kb_locale_id IN (:primary)) DESC, translations.id ASC
              LIMIT 1)
          SQL
          ::KnowledgeBase::Locale.translation_preference_ids(system_locale_or_id),
        ]
      )
    end

    # Preferred translation for many [owner_id, kb_locale_id] pairs at once, resolved with the same
    # fallback as #translation_preferred: the requested locale, then the primary locale, then any
    # translation. Returns a hash keyed by [owner_id, kb_locale_id] mapping to the full translation
    # record; a pair whose owner has no translation at all maps to nil.
    #
    # A LATERAL sub-select picks the single best-matching translation per requested pair (ordered
    # exact-locale → primary → lowest id), so it is one query returning just the chosen row per pair
    # (never every locale of an owner). The requested locale is carried alongside because the chosen
    # row's own locale may be a fallback and cannot be used as the key.
    def preferred_translations_for(pairs)
      pairs = pairs.map { |owner_id, kb_locale_id| [Integer(owner_id), Integer(kb_locale_id)] }.uniq
      return {} if pairs.empty?

      foreign_key = reflect_on_association(:translations).foreign_key

      by_pair = translation_class.find_by_sql(preferred_translations_sql(pairs, foreign_key)).index_by do |translation|
        [translation.public_send(foreign_key).to_i, translation[:requested_kb_locale_id].to_i]
      end

      pairs.index_with { |pair| by_pair[pair] }
    end

    private

    # One LATERAL query per requested pair returning just the chosen translation row (plus the
    # requested locale, carried because the chosen row's own locale may be a fallback).
    def preferred_translations_sql(pairs, foreign_key)
      locale_assoc = translation_class.reflect_on_association(:kb_locale)
      locale_table = locale_assoc.klass.table_name
      locale_fk    = connection.quote_column_name(locale_assoc.foreign_key)
      quoted_fk    = connection.quote_column_name(foreign_key)

      <<~SQL.squish
        SELECT preferred.*, requested.kb_locale_id AS requested_kb_locale_id
        FROM unnest(ARRAY[#{pairs.map(&:first).join(',')}]::bigint[], ARRAY[#{pairs.map(&:last).join(',')}]::bigint[])
          AS requested(owner_id, kb_locale_id)
        JOIN LATERAL (
          SELECT t.*
          FROM #{translation_class.table_name} t
          JOIN #{locale_table} l ON l.id = t.#{locale_fk}
          WHERE t.#{quoted_fk} = requested.owner_id
          ORDER BY (t.#{locale_fk} = requested.kb_locale_id) DESC, l."primary" DESC, t.id ASC
          LIMIT 1
        ) preferred ON TRUE
      SQL
    end
  end

  private

  def validate_translations
    translations.reject(&:valid?).each do |elem|
      elem.errors.each do |error|
        errors.add "translations.#{error.attribute}", error.message
      end
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Locale < ApplicationModel
  include KnowledgeBase::Locale::HasAuditLogs

  belongs_to :knowledge_base, inverse_of: :kb_locales, touch: true
  belongs_to :system_locale, inverse_of: :knowledge_base_locales, class_name: '::Locale'

  validates :primary, uniqueness: { case_sensitive: true, scope: %i[system_locale_id knowledge_base_id] }, if: :primary?
  validates :system_locale_id, uniqueness: { case_sensitive: true, scope: :knowledge_base_id }

  has_many :knowledge_base_translations, class_name:  'KnowledgeBase::Translation',
                                         inverse_of:  :kb_locale,
                                         foreign_key: :kb_locale_id,
                                         dependent:   :destroy

  has_many :category_translations,       class_name:  'KnowledgeBase::Category::Translation',
                                         inverse_of:  :kb_locale,
                                         foreign_key: :kb_locale_id,
                                         dependent:   :destroy

  has_many :answer_translations,         class_name:  'KnowledgeBase::Answer::Translation',
                                         inverse_of:  :kb_locale,
                                         foreign_key: :kb_locale_id,
                                         dependent:   :destroy

  has_many :menu_items,                  class_name:  'KnowledgeBase::MenuItem',
                                         inverse_of:  :kb_locale,
                                         foreign_key: :kb_locale_id,
                                         dependent:   :destroy

  def self.system_with_kb_locales(knowledge_base)
    ::Locale
      .joins(:knowledge_base_locales)
      .where(knowledge_base_locales: { knowledge_base: knowledge_base })
      .select('locales.*, knowledge_base_locales.id as kb_locale_id, knowledge_base_locales.primary as primary_locale')
  end

  def self.preferred(user, knowledge_base)
    preferred_via_system(user, knowledge_base) ||
      preferred_via_kb(user, knowledge_base) ||
      knowledge_base.kb_locales.first
  end

  def self.preferred_via_system(user, knowledge_base)
    knowledge_base
      .kb_locales
      .joins(:system_locale)
      .find_by(locales: { locale: user.locale })
  end

  def self.preferred_via_kb(_user, knowledge_base)
    knowledge_base.kb_locales.find_by(primary: true)
  end

  # The locales the help site's language picker offers an object in: those it is translated to —
  #   and, for a knowledge base or a category, those it holds published content in, where it is
  #   shown under a fallback title (KnowledgeBase.available_in, KnowledgeBase::Category.available_in).
  #   Every locale offered has to lead somewhere.
  #
  # The content is probed per locale row rather than collected: a few index probes that stop at the
  #   first published answer, where collecting the locales of every published answer first scans
  #   them all.
  scope :available_for, lambda { |object|
    translated = where(id: object.translations.select(:kb_locale_id))

    categories = case object
                 when KnowledgeBase::Category then KnowledgeBase::Category.subtree_ids_sql(Integer(object.id))
                 when KnowledgeBase then sanitize_sql_array(['SELECT id FROM knowledge_base_categories WHERE knowledge_base_id = ?', object.id])
                 end

    if categories
      translated.or(where(<<~SQL.squish))
        EXISTS (SELECT 1 FROM knowledge_base_answer_translations
                  JOIN knowledge_base_answers ON knowledge_base_answers.id = knowledge_base_answer_translations.answer_id
                 WHERE knowledge_base_answer_translations.kb_locale_id = knowledge_base_locales.id
                   AND knowledge_base_answers.category_id IN (#{categories})
                   AND #{KnowledgeBase::Answer.published_sql}
                 OFFSET 0)
      SQL
    else
      translated
    end
  }

  # The ids a listing prefers when picking the translation a record is *shown* under: those of the
  #   browsed system locale first, then the primary ones. Resolved in one query per request so the
  #   subqueries of HasTranslations.preferred_translation_sql can compare ids directly instead of
  #   joining this table once per row — worth about
  #   40% of the ordering cost on a large category.
  #
  # Sets rather than single ids because several knowledge bases can share a system locale, and this
  #   deliberately does not take one: every translation of a given record belongs to one knowledge
  #   base, so at most one id from either set can match a row.
  #
  # @param system_locale_or_id [Locale, Integer, nil] the browsed locale, as in HasTranslations.localed
  # @return [Hash{Symbol => Array<Integer>}] `:browsed` and `:primary` kb_locale ids
  def self.translation_preference_ids(system_locale_or_id)
    system_locale_id = system_locale_or_id.try(:id) || system_locale_or_id

    # Once per request rather than once per listing: a category page resolves the preference for
    #   its own lookup, its breadcrumb, its two listings and their orders. Any commit clears it.
    Auth::RequestCache.fetch_value("knowledge_base_locale/translation_preference_ids/#{system_locale_id}") do
      locales = pluck(:id, :system_locale_id, :primary)

      {
        browsed: locales.filter_map { |id, locale_system_locale_id, _primary| id if system_locale_id.present? && locale_system_locale_id == system_locale_id },
        primary: locales.filter_map { |id, _system_locale_id, primary| id if primary },
      }
    end
  end
end

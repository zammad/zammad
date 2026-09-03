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

  scope :available_for, ->(object) { where(id: object.translations.select(:kb_locale_id)) }

  # The ids a listing prefers when picking the translation a record is *shown* under: those of the
  #   browsed system locale first, then the primary ones. Resolved in one query per listing so the
  #   ORDER BY subqueries of KnowledgeBase::Answer.preferred_translation_sql and its category
  #   counterpart can compare ids directly instead of joining this table once per row — worth about
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
    locales          = select(:id, :system_locale_id, :primary).to_a

    {
      browsed: locales.select { |locale| system_locale_id.present? && locale.system_locale_id == system_locale_id }.map(&:id),
      primary: locales.select(&:primary?).map(&:id),
    }
  end
end

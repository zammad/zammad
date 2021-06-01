# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::Locale < ApplicationModel
  belongs_to :knowledge_base, inverse_of: :kb_locales, touch: true
  belongs_to :system_locale, inverse_of: :knowledge_base_locales, class_name: '::Locale'

  validates :primary, uniqueness: { scope: %i[system_locale_id knowledge_base_id] }, if: :primary?
  validates :system_locale_id, uniqueness: { scope: :knowledge_base_id }

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
end

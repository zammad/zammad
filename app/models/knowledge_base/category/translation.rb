# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::Category::Translation < ApplicationModel
  include HasAgentAllowedParams
  include HasSearchIndexBackend
  include KnowledgeBase::Search
  include KnowledgeBase::HasUniqueTitle

  AGENT_ALLOWED_ATTRIBUTES = %i[title kb_locale_id].freeze

  belongs_to :kb_locale, class_name: 'KnowledgeBase::Locale', inverse_of: :category_translations
  validates  :kb_locale, presence: true

  belongs_to :category,  class_name: 'KnowledgeBase::Category', inverse_of: :translations, touch: true
  validates  :category,  presence: true

  validates :title,        presence: true
  validates :kb_locale_id, uniqueness: { scope: :category_id }

  scope :neighbours_of, ->(translation) { joins(:category).where(knowledge_base_categories: { parent_id: translation.category&.parent_id }) }

  def to_param
    [category_id, title.parameterize].join('-')
  end

  def assets(data)
    return data if assets_added_to?(data)

    data = super(data)
    category.assets(data)
  end

  def search_index_attribute_lookup(include_references: true)
    attrs = super

    attrs['title']    = ActionController::Base.helpers.strip_tags attrs['title']
    attrs['scope_id'] = category.parent_id

    attrs
  end

  class << self
    def search_fallback(query, scope = nil, options: {})
      fields = %w[title]

      output = where_or_cis(fields, query)

      if scope.present?
        output = output
                 .joins(:category)
                 .where(knowledge_base_categories: { parent_id: scope })
      end

      output
    end
  end
end

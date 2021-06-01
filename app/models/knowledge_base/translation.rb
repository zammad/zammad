# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::Translation < ApplicationModel
  include HasAgentAllowedParams
  include HasSearchIndexBackend
  include KnowledgeBase::Search

  AGENT_ALLOWED_ATTRIBUTES = %i[title footer_note kb_locale_id].freeze

  belongs_to :knowledge_base, inverse_of: :translations, touch: true
  belongs_to :kb_locale,      inverse_of: :knowledge_base_translations, class_name: 'KnowledgeBase::Locale'

  validates :title,        presence: true, length: { maximum: 250 }
  validates :kb_locale_id, uniqueness: { scope: :knowledge_base_id }

  def assets(data)
    return data if assets_added_to?(data)

    data = super(data)
    knowledge_base.assets(data)
  end

  def search_index_attribute_lookup(include_references: true)
    attrs = super

    attrs['title'] = ActionController::Base.helpers.strip_tags attrs['title']

    attrs
  end

  class << self
    def search_fallback(query, scope = nil, options: {})
      fields = %w[title]

      output = where_or_cis(fields, query)

      if scope.present?
        output = output.where(id: 0) # KB cannot be in any scope
      end

      output
    end
  end
end

# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Answer::Translation < ApplicationModel
  include HasDefaultModelUserRelations

  include HasAgentAllowedParams
  include HasLinks
  include HasSearchIndexBackend
  include KnowledgeBase::HasUniqueTitle
  include KnowledgeBase::Answer::Translation::Search

  AGENT_ALLOWED_ATTRIBUTES       = %i[title kb_locale_id].freeze
  AGENT_ALLOWED_NESTED_RELATIONS = %i[content].freeze

  belongs_to :kb_locale,  class_name: 'KnowledgeBase::Locale', inverse_of: :answer_translations
  belongs_to :answer,     class_name: 'KnowledgeBase::Answer', inverse_of: :translations, touch: true

  belongs_to                    :content, class_name: 'KnowledgeBase::Answer::Translation::Content', inverse_of: :translation, dependent: :destroy
  accepts_nested_attributes_for :content, update_only: true

  validates :title,        presence: true, length: { maximum: 250 }
  validates :kb_locale_id, uniqueness: { case_sensitive: true, scope: :answer_id }

  scope :neighbours_of, ->(translation) { joins(:answer).where(knowledge_base_answers: { category_id: translation.answer&.category_id }) }

  alias assets_essential assets

  def assets(data = {})
    return data if assets_added_to?(data)

    data = super
    answer.assets(data)
    ApplicationModel::CanAssets.reduce inline_linked_objects, data
  end

  def to_param
    [answer_id, title.parameterize].join('-')
  end

  def search_index_attribute_lookup(include_references: true)
    attrs = super

    attrs.merge('title'      => ActionController::Base.helpers.strip_tags(attrs['title']),
                'content'    => content&.search_index_attribute_lookup,
                'scope_id'   => answer.category_id,
                'attachment' => answer.attachments_for_search_index_attribute_lookup,
                'tags'       => answer.tag_list)
  end

  def inline_linked_objects
    output = []

    scrubber = Loofah::Scrubber.new do |node|
      next if node.name != 'a'
      next if !node.key? 'data-target-type'

      case node['data-target-type']
      when 'knowledge-base-answer'
        if (translation = KnowledgeBase::Answer::Translation.find_by(id: node['data-target-id']))
          output.push translation
        end
      end
    end

    Loofah.scrub_fragment(content.body, scrubber)

    output
  end

  scope :search_sql_text_fallback, lambda { |query|
    fields = %w[title]
    fields << KnowledgeBase::Answer::Translation::Content.arel_table[:body]

    where_or_cis(fields, query).joins(:content)
  }

  scope :apply_kb_scope, lambda { |scope|
    if scope.present?
      output
        .joins(:answer)
        .where(knowledge_base_answers: { category_id: scope })
    end
  }
end

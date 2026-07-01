# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Answer::Translation < ApplicationModel
  include HasDefaultModelUserRelations
  include HasOnlineNotifications

  include HasAgentAllowedParams
  include HasLinks
  include HasSearchIndexBackend
  include HasVectorIndex
  include KnowledgeBase::HasUniqueTitle
  include KnowledgeBase::Answer::Translation::Search

  AGENT_ALLOWED_ATTRIBUTES       = %i[title kb_locale_id].freeze
  AGENT_ALLOWED_NESTED_RELATIONS = %i[content].freeze

  belongs_to :kb_locale,  class_name: 'KnowledgeBase::Locale', inverse_of: :answer_translations
  belongs_to :answer,     class_name: 'KnowledgeBase::Answer', inverse_of: :translations, touch: true

  belongs_to                    :content, class_name: 'KnowledgeBase::Answer::Translation::Content', inverse_of: :translation, dependent: :destroy
  accepts_nested_attributes_for :content, update_only: true

  # Embedding cache rows are cleaned up with the record they belong to.
  has_many :ai_stored_results, class_name: 'AI::StoredResult', as: :related_object, dependent: :destroy

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

    attrs['title']             = ActionController::Base.helpers.strip_tags(title)
    attrs['content']           = content&.search_index_attribute_lookup
    attrs['scope_id']          = answer.category_id
    attrs['tags']              = answer.tag_list
    attrs['attachment']        = answer.search_index_attachments_lookup(attrs.to_json.bytesize)

    # Index the answer's publication state for the `publication_state:`
    # search syntax.
    attrs['publication_state'] = answer_publication_state

    attrs
  end

  scope :vector_index_scope, lambda {
    relevant_category_ids = Setting.get('vectordb_knowledge_base_category_ids')

    # PoC: index drafts too (not only internally-visible answers), but still exclude archived ones.
    answer_scope = KnowledgeBase::Answer.date_later_or_nil(:archived_at, Time.zone.now)

    # For now only explicitly enabled categories are indexed.
    return answer_scope.none if relevant_category_ids.blank?

    answer_scope = answer_scope.where(category: relevant_category_ids)

    joins(:answer).merge(answer_scope).includes(:content, :kb_locale)
  }

  def vector_index_data
    {
      content:              ::Text::ContentCleanup.new(content: content.body).cleanup,
      content_meta_headers: [title],
      metadata:             {
        answer_id:          answer_id,
        locale:             kb_locale.system_locale.locale,
        category_id:        answer.category_id,
        visible_internally: answer.visible_internally?,
      },
    }
  end

  def vector_index_content_changed?
    # Title is prepended to every chunk as a header, so a title change requires re-embedding. The
    # body lives on the associated content record and is invisible here, so that change arrives via
    # the vector_index_content_dirty flag (set in Content#touch_translation). Everything else
    # (locale, category, visibility) is metadata only and handled by the cheap update path.
    vector_index_content_dirty || previous_changes.key?('title')
  end

  def vector_indexing_for_record?
    # PoC: index drafts too (visible_internally? guard omitted for now), but not archived answers.
    return false if answer.archived_at&.past?

    # For now only explicitly enabled categories are indexed.
    relevant_category_ids = Setting.get('vectordb_knowledge_base_category_ids')
    return false if relevant_category_ids.blank? || relevant_category_ids.map(&:to_i).exclude?(answer.category_id)

    true
  end

  def vector_index_chunking_strategy
    Setting.get('vectordb_knowledge_base_chunking_strategy')&.to_sym
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
      joins(:answer)
        .where(knowledge_base_answers: { category_id: scope })
    end
  }

  private

  def answer_publication_state
    answer.can_be_published_aasm.calculated_state
  end
end

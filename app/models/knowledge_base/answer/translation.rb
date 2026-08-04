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

  before_save :set_edited_at, if: :edited?

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
    # Index every answer regardless of its publication state (drafts and archived ones included) —
    # whether a user may receive it as a suggestion is decided by the search's permission filter
    # (Service::KnowledgeBase::Answer::SimilaritySearch).
    #
    # Every category is indexed unless it (or one of its ancestors) is excluded. The bulk counterpart
    # to #vector_indexing_for_record?: one expanded id list filters the whole reload, rather than
    # being asked about one answer at a time.
    answer_scope = KnowledgeBase::Answer.in_vector_indexable_category

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

  def vector_indexing_for_record?
    # Index answers of any publication state (drafts and archived ones included, so the
    # visible_internally? guard is omitted); the search's permission filter decides who may receive
    # them as a suggestion.
    #
    # Every category is indexed unless it (or one of its ancestors) is explicitly excluded. Passing
    # the id spares this check from loading the category record just to look it up in the list.
    KnowledgeBase::Category.vector_indexable?(answer.category_id)
  end

  def vector_index_chunking_strategy
    Setting.get('vectordb_knowledge_base_chunking_strategy')&.to_sym
  end

  # Answer attributes that feed this translation's vector document: category (indexing scope +
  # metadata) and the state timestamps (drive the visible_internally metadata).
  VECTOR_INDEX_ANSWER_ATTRIBUTES = %w[category_id internal_at published_at archived_at].freeze

  # Did anything feeding the vector document change? Title/locale live here, the body on the content
  # record, the rest on the answer — each is read off its own record's previous_changes. This works
  # because Answer#touch_translations uses touch_later, which preserves previous_changes on a
  # translation edited in the same transaction (an immediate touch would reset them). previous_changes
  # can be stale on long-lived instances, which errs towards an extra (no-op) reindex, never a skip
  # of a real change.
  def vector_index_relevant_change?
    return true if previous_changes.keys.intersect?(%w[title kb_locale_id])
    return true if content&.previous_changes&.key?('body')

    answer&.previous_changes&.keys&.intersect?(VECTOR_INDEX_ANSWER_ATTRIBUTES) || false
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

  def edited?
    return true if new_record?

    title_changed?
  end

  def set_edited_at
    self.edited_at = Time.zone.now
  end

  def answer_publication_state
    answer.can_be_published_aasm.calculated_state
  end
end

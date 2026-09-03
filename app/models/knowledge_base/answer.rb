# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Answer < ApplicationModel
  include HasTranslations
  include HasAgentAllowedParams
  include HasTags
  include HasTaskbars
  include CanBePublished
  include ChecksKbClientNotification
  include ChecksKbClientVisibility
  include TriggersKnowledgeBaseContentUpdates
  include KnowledgeBase::Answer::TriggersSubscriptions
  include CanCloneAttachments
  include CanLookupSearchIndexAttributesWithAttachments

  AGENT_ALLOWED_ATTRIBUTES       = %i[category_id promoted internal_note].freeze
  AGENT_ALLOWED_NESTED_RELATIONS = %i[translations].freeze

  # The create view of the new interface lives in its own taskbar tab, holding the draft until it
  #   is saved. There is no record behind such a tab, so its key carries a UUID instead of an id
  #   (see Gql::Types::User::TaskbarItemType#object_entity!).
  #
  # The edit view is one tab per answer *and* locale, just like its URL: an answer is edited one
  #   translation at a time. The answer is the tab's entity all the same, with the locale as the
  #   qualifier of its key ('KnowledgeBase__Answer-42-de-de', see Taskbar.entity_key) — a
  #   translation could not be, because a locale that has none yet is exactly where an answer gets
  #   its next one, and there would be no record to key that tab on.
  taskbar_entities 'KnowledgeBaseAnswerCreate', 'KnowledgeBaseAnswerEdit'

  # An answer is offered for reading to a reader of its category, so #show? would grant an edit tab
  #   the edit view then refuses.
  taskbar_entity_pundit_methods 'KnowledgeBaseAnswerEdit' => :update?

  # Only the edit tab carries the answer's own key ('KnowledgeBase__Answer-42-de-de'): a create tab
  #   has no record to key on, and reading an answer opens no tab at all. So an entry under this key
  #   is always somebody editing, and #update? is what decides whether they still may — an editor
  #   who lost access to the subtree drops out of the others' lists on the next update.
  taskbar_live_user_pundit_method :update?

  belongs_to :category, class_name: 'KnowledgeBase::Category', inverse_of: :answers, touch: true

  scope :include_contents, -> { eager_load(translations: :content) }
  scope :sorted,           -> { order(position: :asc) }

  scope :sorted_by_published, lambda { |system_locale_or_id|
    localed(system_locale_or_id)
      .reorder(Arel.sql('GREATEST(knowledge_base_answers.published_at, knowledge_base_answer_translations.edited_at) DESC'))
      .published
  }
  scope :sorted_by_internally_published, lambda { |system_locale_or_id|
    localed(system_locale_or_id)
      .reorder(Arel.sql('GREATEST(LEAST(knowledge_base_answers.internal_at, knowledge_base_answers.published_at), knowledge_base_answer_translations.edited_at) DESC'))
      .internal
  }

  # Orders a category's answers in that category's `answer_sorting_mode`, for both stacks: the
  #   desktop view through Service::KnowledgeBase::Answers and the public help site through
  #   KnowledgeBase::Public::BaseController#answers_filter. Kept here rather than in either of them
  #   so the two cannot drift apart.
  #
  # The id is the tie-breaker in every mode: positions are not unique-constrained, and titles and
  #   timestamps can collide just as well.
  #
  # @param mode [String] one of KnowledgeBase::SORTING_MODES
  # @param system_locale_or_id [Locale, Integer, nil] the browsed locale, as in .localed
  # @param internal [Boolean] whether the caller shows internally published content. The public
  #   help site must not order by a timestamp it does not show, so it dates an answer by its
  #   publication alone, while the internal listing dates it from whichever came first.
  scope :sorted_by_mode, lambda { |mode, system_locale_or_id: nil, internal: true|
    case mode
    when 'alphabetical'
      reorder(Arel.sql("LOWER(#{preferred_translation_sql(:title, system_locale_or_id)}) ASC, knowledge_base_answers.id ASC"))
    when 'last_update'
      # GREATEST/LEAST ignore NULLs in PostgreSQL, so a draft (no publication timestamps at all)
      #   falls back to its edit date, and an internal-only answer to internal_at. Only an answer
      #   with neither yields NULL, which NULLS LAST keeps off the top.
      reorder(Arel.sql("GREATEST(#{publication_timestamp_sql(internal)}, #{preferred_translation_sql(:edited_at, system_locale_or_id)}) DESC NULLS LAST, knowledge_base_answers.id ASC"))
    else
      reorder(position: :asc, id: :asc)
    end
  }

  # Drops the answers whose category (or one of its ancestors) is excluded from the vector index.
  # A no-op while nothing is excluded, which is the default.
  scope :in_vector_indexable_category, lambda {
    excluded_category_ids = KnowledgeBase::Category.vector_excluded_category_ids

    where.not(category_id: excluded_category_ids) if excluded_category_ids.present?
  }

  acts_as_list scope: :category, top_of_list: 0

  # Provide consistent naming with KB category
  #
  # Originally this used alias_attribute. But alias_attribute for relations for deprecated in Rails 7.1 and removed in 7.2
  # However, alias_association was not merged in time for 7.2... So here is a workaround that will hopefully get removed in 7.3!
  #
  # Related PR: https://github.com/rails/rails/pull/49801
  alias parent category
  alias parent= category=

  alias assets_essential assets

  def attributes_with_association_ids
    attrs = super
    attrs[:attachments] = attachments_sorted.map { |elem| self.class.attachment_to_hash(elem) }
    attrs[:tags]        = tag_list
    attrs
  end

  def assets(data = {})
    return data if assets_added_to?(data)

    data = super
    data = category.assets(data)

    ApplicationModel::CanAssets.reduce(translations, data)
  end

  attachments_cleanup!

  def attachments_sorted
    attachments.sort_by { |elem| elem.filename.downcase }
  end

  def add_attachment(file)
    filename     = file.try(:original_filename) || File.basename(file.path)
    content_type = file.try(:content_type) || MIME::Types.type_for(filename).first&.content_type || 'application/octet-stream'

    Store.create!(
      object:      self.class.name,
      o_id:        id,
      data:        file.read,
      filename:    filename,
      preferences: { 'Content-Type': content_type }
    )

    touch # rubocop:disable Rails/SkipsModelValidations
    translations.each(&:touch)

    true
  end

  def remove_attachment(attachment_id)
    attachment = attachments.find { |elem| elem.id == attachment_id.to_i }

    raise ActiveRecord::RecordNotFound if attachment.nil?

    Store.remove_item(attachment.id)

    touch # rubocop:disable Rails/SkipsModelValidations
    translations.each(&:touch)

    true
  end

  def api_url
    Rails.application.routes.url_helpers.knowledge_base_answer_path(category.knowledge_base, self)
  end

  # required by CanCloneAttachments
  def content_type
    'text/html'
  end

  private

  # Filing an answer in a category is a change to what that category holds, so it counts as an edit
  #   of it and of everything above it — in every locale the answer is translated to, since the
  #   whole answer moved, not one of its translations.
  #
  # The category it came *out* of is deliberately left alone, and destroying an answer bumps
  #   nothing: what is gone cannot date a listing. Both would otherwise float a category to the top
  #   for having lost content.
  def bump_category_edited_at
    ::KnowledgeBase::Category::Translation.bump_edited_at(category, translations.map(&:kb_locale_id))
  end
  after_update :bump_category_edited_at, if: :saved_change_to_category_id?

  # Keep each translation's indexes fresh when the answer changes (tags, category, publication
  # state, …). Both reindex hooks live on the translation's own after_commit — the search index via
  # HasSearchIndexBackend and the vector index via HasVectorIndex (which also gates on vector store
  # availability) — so the answer only has to nudge its translations; no vector-specific logic here.
  #
  # touch_later (the deferred touch belongs_to touch: uses) instead of touch: it still bumps
  # updated_at and fires the translation's callbacks, but coalesces repeated touch-backs of the same
  # translation within a transaction into a single write.
  def touch_translations
    translations
      .reject(&:destroyed?)
      .each(&:touch_later)
  end
  after_save :touch_translations
  after_touch :touch_translations

  class << self
    # The value of one column of the translation an answer is *shown* under, as a scalar subquery
    #   usable in ORDER BY.
    #
    # A correlated subquery rather than a join, for two reasons. `localed` (which
    #   .sorted_by_published uses) inner-joins and would drop every answer without a translation in
    #   the browsed locale — editors have to keep seeing those. And the fallback needs the three
    #   levels of Gql::Types::KnowledgeBase::AnswerType#preferred_translation (requested locale,
    #   then the primary locale, then any), which the ORDER BY below expresses as one preference
    #   chain instead of one outer join per level.
    #
    # The preference is compared against kb_locale ids resolved once for the whole listing rather
    #   than joined per row — see KnowledgeBase::Locale.translation_preference_ids, which also
    #   explains why each preference is a set. With no locale browsed the first set is empty, so
    #   the primary-locale translation wins, exactly as it does for the displayed one.
    def preferred_translation_sql(column, system_locale_or_id)
      ActiveRecord::Base.sanitize_sql_array(
        [
          <<~SQL.squish,
            (SELECT translations.#{connection.quote_column_name(column)}
               FROM knowledge_base_answer_translations translations
              WHERE translations.answer_id = knowledge_base_answers.id
              ORDER BY (translations.kb_locale_id IN (:browsed)) DESC, (translations.kb_locale_id IN (:primary)) DESC, translations.id ASC
              LIMIT 1)
          SQL
          ::KnowledgeBase::Locale.translation_preference_ids(system_locale_or_id),
        ]
      )
    end

    # When an answer became visible to the audience doing the browsing — the counterpart of the
    #   timestamps .sorted_by_published and .sorted_by_internally_published pair with the edit date.
    def publication_timestamp_sql(internal)
      if internal
        'LEAST(knowledge_base_answers.internal_at, knowledge_base_answers.published_at)'
      else
        'knowledge_base_answers.published_at'
      end
    end

    def attachment_to_hash(attachment)
      url = Rails.application.routes.url_helpers.attachment_path(attachment.id)

      {
        id:          attachment.id,
        url:         url,
        preview_url: "#{url}?preview=1",
        filename:    attachment.filename,
        size:        attachment.size,
        preferences: attachment.preferences
      }
    end
  end
end

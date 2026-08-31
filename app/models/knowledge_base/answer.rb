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
  after_save  :touch_translations
  after_touch :touch_translations

  class << self
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

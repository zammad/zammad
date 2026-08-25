# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Creates a knowledge base answer, with its title and body in one locale, its attachments and its
#   tags.
class Service::KnowledgeBase::Answer::Create < Service::KnowledgeBase::Base
  # Authorizes through KnowledgeBase::AnswerPolicy, which needs a user.
  requires_current_user!

  # Every state but `draft` is stored as the timestamp column of its own name — the enum mirrors the
  #   CanBePublished states, which are named after those columns. Listed rather than interpolated
  #   from the state: it arrives from outside, and the columns a create may write are none of the
  #   caller's choosing. A state missing here is a programming error, hence the `fetch` below.
  VISIBILITY_TIMESTAMPS = {
    internal:  :internal_at=,
    published: :published_at=,
    archived:  :archived_at=,
  }.freeze

  attr_reader :answer_data

  # @param answer_data [Hash] `category`, `title`, `body`, `tags`, `visibility` (a `state` plus an
  #   optional `scheduled_at`) and an optional `form_id`, as sent by
  #   Gql::Types::Input::KnowledgeBase::CreateAnswerInputType — which is what settles that all but
  #   the form id are there, so nothing checks for them again here
  # @param kb_locale [KnowledgeBase::Locale, String] locale the submitted title and body are for, as
  #   record or as system locale code
  def initialize(answer_data:, kb_locale:)
    @answer_data         = answer_data
    @submitted_kb_locale = kb_locale
  end

  def category
    answer_data[:category]
  end

  def execute
    ensure_category_of_knowledge_base!

    answer = ActiveRecord::Base.transaction do
      built = build_answer

      # Editor access to the category is what allows filing an answer in it — asked of the built
      #   answer, the way the category service asks CategoryPolicy#create? of the built category.
      Pundit.authorize current_user, built, :create?

      built.save!

      attach_files(built)
      assign_tags(built)

      built
    end

    cleanup_upload_cache

    answer
  end

  private

  def build_answer
    ::KnowledgeBase::Answer.new(category: category).tap do |answer|
      build_translation(answer)
      assign_visibility(answer)
    end
  end

  # Title and body live on the translation of one locale, not on the answer.
  def build_translation(answer)
    answer.translations
      .build(kb_locale: kb_locale, title: answer_data[:title])
      .build_content(body: answer_data[:body])
  end

  # `archived` is offered while creating, as agreed for the create form: the state machine reaches
  #   it only from `internal` or `published`, but the state is *derived* from the timestamps rather
  #   than from a transition, and the ordering validations only compare the ones that are set — so
  #   an `archived_at` on its own is a coherent archived answer. It is what the old interface writes
  #   too (HasPublishing#has_publishing_update permits the column directly, and its dialog treats
  #   draft → archived as a forward move).
  def assign_visibility(answer)
    visibility = answer_data[:visibility]
    return if visibility[:state] == :draft

    # A point in time in the future leaves the answer a draft until then: CanBePublished derives the
    #   state by comparing these timestamps with the current time, and schedules the touch that
    #   makes the answer surface once it is reached.
    answer.public_send(VISIBILITY_TIMESTAMPS.fetch(visibility[:state]), visibility[:scheduled_at] || Time.zone.now)
  end

  # The model's own way in from a form's upload cache. It skips the cache's inline images — those
  #   belong to the body, and HasRichText pulls them out of it into attachments of the translation
  #   content — and clears the record's existing files first, which on a fresh answer is nothing.
  #
  # Not `answer.attachments=`: that buffer credits the store item to the record's `created_by_id`,
  #   and `knowledge_base_answers` has no such column.
  def attach_files(answer)
    return if form_id.blank?

    answer.attach_upload_cache(form_id)
  end

  # An empty list is what "no tags" looks like, so there is nothing to guard against here.
  def assign_tags(answer)
    answer_data[:tags].each do |tag|
      # Creating a tag that does not exist yet is what the `tag_new` setting governs, so an
      #   unknown tag is skipped rather than refused — the same as in Service::Ticket::Create.
      next if !::Tag.tag_allowed?(name: tag.strip, user_id: current_user.id)

      answer.tag_add(tag.strip, current_user.id)
    end
  end

  # `attach_upload_cache` copies, it does not move — the files now belong to the answer, and the
  #   draft they were uploaded for is gone, so the cache has nothing left to hold.
  #
  # Not left to the taskbar the client deletes afterwards (Taskbar::HasAttachments clears its cache
  #   on destroy), the way the shared draft services leave it to the form that stays open: a client
  #   that keeps the tab around would strand the files for good, since UploadCacheCleanupJob skips
  #   every form id a taskbar still points at. The ticket create path cleans up for the same reason
  #   (Service::Ticket::Article::Create#form_id_cleanup).
  def cleanup_upload_cache
    return if form_id.blank?

    UploadCache.new(form_id).destroy
  rescue ActiveRecord::RecordNotFound
    # Someone emptied the cache first: another session closing the draft tab does the same thing
    #   (Taskbar::HasAttachments clears it after_destroy), and Store.remove_item raises on rows it
    #   no longer finds. The wanted end state is reached either way, while raising would report an
    #   answer that is already committed as a failed create - and a client retrying that would file
    #   the answer twice.
  end

  def form_id
    answer_data[:form_id]
  end

  # Nothing relates the answer's category to the knowledge base every write goes to, so a category
  #   of another one would save happily — and leave an answer in a tree whose locale it was never
  #   written for.
  #
  # This is also where an inactive knowledge base is refused, since resolving it is what the
  #   comparison needs. Asserting it separately would be the same call twice: creating an answer is
  #   editing knowledge base content, so it follows the same rule as the category services — only
  #   while the knowledge base is active.
  def ensure_category_of_knowledge_base!
    return if category.knowledge_base_id == active_knowledge_base!.id

    raise Exceptions::UnprocessableContent, __('The selected category does not belong to this knowledge base.')
  end
end

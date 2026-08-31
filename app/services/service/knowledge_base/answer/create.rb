# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Creates a knowledge base answer, with its title and body in one locale, its attachments and its
#   tags. What each of those means is Service::KnowledgeBase::Answer::Base's business, which
#   Service::KnowledgeBase::Answer::Update shares.
class Service::KnowledgeBase::Answer::Create < Service::KnowledgeBase::Answer::Base
  attr_reader :answer_data

  # @param answer_data [Hash] `category`, `title`, `body`, `tags`, `visibility` (the publication
  #   state to create the answer in) and an optional `form_id`, as sent by
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
    ensure_category_of_knowledge_base!(category)

    answer = ActiveRecord::Base.transaction do
      built = build_answer

      # Editor access to the category is what allows filing an answer in it — asked of the built
      #   answer, the way the category service asks CategoryPolicy#create? of the built category.
      Pundit.authorize current_user, built, :create?

      built.save!

      attach_files(built, answer_data[:form_id])
      assign_tags(built, answer_data[:tags])

      built
    end

    cleanup_upload_cache

    answer
  end

  private

  # `archived` is offered while creating, as agreed for the create form: the state machine reaches it
  #   only from `internal` or `published`, but the state is *derived* from the timestamps rather than
  #   from a transition, and the ordering validations only compare the ones that are set — so an
  #   `archived_at` on its own is a coherent archived answer. It is what the old interface writes too
  #   (HasPublishing#has_publishing_update permits the column directly, and its dialog treats
  #   draft → archived as a forward move).
  def build_answer
    ::KnowledgeBase::Answer.new(category: category).tap do |answer|
      assign_translation(answer, kb_locale, title: answer_data[:title], body: answer_data[:body])
      assign_visibility(answer, answer_data[:visibility])
    end
  end

  # `attach_upload_cache` copies, it does not move — the files now belong to the answer, and the
  #   draft they were uploaded for is gone, so the cache has nothing left to hold. An update keeps
  #   its cache instead: the tab it was submitted from stays open, and its next save reads the cache
  #   again.
  #
  # Not left to the taskbar the client deletes afterwards (Taskbar::HasAttachments clears its cache
  #   on destroy), the way the shared draft services leave it to the form that stays open: a client
  #   that keeps the tab around would strand the files for good, since UploadCacheCleanupJob skips
  #   every form id a taskbar still points at. The ticket create path cleans up for the same reason
  #   (Service::Ticket::Article::Create#form_id_cleanup, which also clears the state of the tab it
  #   was submitted from - a ticket tab stays open, while every answer create leaves its tab).
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
end

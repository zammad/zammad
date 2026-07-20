# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Emit a ping on the knowledgeBaseContentUpdates subscription whenever a browse-
#   relevant record changes (create/update/destroy, incl. translation touches),
#   so desktop browse views refetch the scoped queries.
module TriggersKnowledgeBaseContentUpdates
  extend ActiveSupport::Concern

  included do
    after_commit :trigger_knowledge_base_content_updates
  end

  private

  def trigger_knowledge_base_content_updates
    Gql::Subscriptions::KnowledgeBase::ContentUpdates.trigger({ categories: content_update_affected_categories })
  end

  # The changed category and its ancestors — their counts/visibility may change.
  #   Empty for knowledge-base-wide changes (KB record / translations), signalling
  #   subscribers to refetch broadly.
  #
  # On a move (answer/category reparented) this returns only the *new* path. The
  #   *old* category is still invalidated: `belongs_to … touch: true` on
  #   `Answer#category` / `Category#parent` touches the previous record too, so it
  #   fires its own ping (with itself first in the affected ids). Keep that in
  #   mind before dropping those `touch: true`s or moving via callback-skipping
  #   writes (`update_column`/`update_all`), which would leave the old view stale.
  def content_update_affected_categories
    category = case self
               when KnowledgeBase::Answer   then self.category
               when KnowledgeBase::Category then self
               end

    category ? category.self_with_parents : []
  rescue
    []
  end
end

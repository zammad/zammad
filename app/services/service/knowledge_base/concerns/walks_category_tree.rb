# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The category tree of one knowledge base, loaded once and walked in memory, plus the content
#   visibility derived from it.
#
# Both services that render a list of categories need the same three things per category: its
#   ancestor path, its subtree, and the highest publication state present in that subtree. Asking
#   the model for any of them costs a recursive CTE per call and per publication state
#   (KnowledgeBase::Category#self_with_parents, #self_with_children_ids, #content_visibility), so
#   the browse grid (Service::KnowledgeBase::CategoryContent) and the search result list
#   (Service::KnowledgeBase::Search) both batch them through here instead — and, just as
#   importantly, agree on the answer, since a category has to read the same in both places.
#
# Including services must provide `knowledge_base` and `locale` (the browsed
#   KnowledgeBase::Locale, or nil for no locale gate).
module Service::KnowledgeBase::Concerns::WalksCategoryTree
  extend ActiveSupport::Concern

  # Publication states in the order KnowledgeBase::Category#content_visibility reports them: the
  # first one present in a category's subtree wins, and a subtree with none of them is a draft.
  VISIBILITY_STATES = %i[published internal archived].freeze

  private

  def all_categories
    @all_categories ||= knowledge_base.categories.to_a
  end

  def categories_by_id
    @categories_by_id ||= all_categories.index_by(&:id)
  end

  def all_category_ids
    @all_category_ids ||= all_categories.map(&:id)
  end

  def children_by_parent
    @children_by_parent ||= all_categories.group_by(&:parent_id)
  end

  # Ancestor path of a category, root first and including the category itself, so no parent-walk
  #   queries are needed. Takes the record rather than an id, because the opened category is not
  #   necessarily one of the loaded ones.
  #
  # `seen` guards a parent_id cycle, which would otherwise never terminate. The model rules one out
  #   (KnowledgeBase::Category#cannot_be_child_of_parent), but corrupt data must not hang a
  #   listing — #self_with_parents takes the same precaution for the same reason.
  def trail_of(category)
    return [] if category.nil?

    @trail_of ||= {}
    @trail_of[category.id] ||= begin
      trail = []
      seen  = Set.new
      node  = category

      while node && seen.add?(node.id)
        trail.unshift(node)
        node = node.parent_id && categories_by_id[node.parent_id]
      end

      trail
    end
  end

  # Ids of a category's subtree, including the category itself. Memoized per id and defined over
  #   the children's own subtrees, so resolving every category costs one pass over the tree rather
  #   than a walk per category — while a caller that only asks about a handful of categories, as
  #   the search result list does, still pays for their branches alone.
  #
  # `visiting` is the cycle guard, as in #trail_of. A single parent_id means no category is
  #   reachable twice in a healthy tree, so it never fires there.
  def subtree_ids(id, visiting = Set.new)
    return Set[id] if !visiting.add?(id)

    @subtree_ids ||= {}
    @subtree_ids[id] ||= Array(children_by_parent[id])
      .each_with_object(Set[id]) { |child, ids| ids.merge(subtree_ids(child.id, visiting)) }
  end

  # Highest publication state present in a category's subtree in the browsed locale, independent of
  #   the current user — the batched equivalent of KnowledgeBase::Category#content_visibility.
  #
  # Untranslated content does not count, mirroring the agent app, which leaves such a category
  #   showing as draft.
  def content_visibility(id)
    VISIBILITY_STATES.find { |state| subtree_answers?(id, state) } || :draft
  end

  def subtree_answers?(id, state)
    subtree_ids(id).intersect?(category_ids_with_answers(state))
  end

  # Ids of every category whose subtree holds at least one answer in the given publication state —
  #   what the browse grid needs to decide which categories are worth showing at all.
  def category_ids_with_subtree_answers(state)
    @category_ids_with_subtree_answers ||= {}
    @category_ids_with_subtree_answers[state] ||= all_category_ids.select { |id| subtree_answers?(id, state) }.to_set
  end

  # Ids of the categories directly holding at least one answer in the given publication state, in
  #   the browsed locale — one query per state for the whole page, and only for the states the
  #   callers actually get to ask about.
  def category_ids_with_answers(state)
    @category_ids_with_answers ||= {}
    @category_ids_with_answers[state] ||= begin
      answers = ::KnowledgeBase::Answer.public_send(state)
      answers = answers.translated_to(locale) if locale

      answers.where(category_id: all_category_ids).distinct.pluck(:category_id).to_set
    end
  end
end

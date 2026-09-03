# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Sets how the categories listed inside one node — the knowledge base root or a single category — are
#   ordered, and stores their hand-made order while that mode is `manual`. The answers of a category
#   are a list of their own, ordered by Service::KnowledgeBase::Reorder::Answers, and are left
#   untouched here.
#
# One service for both nodes, the way Service::KnowledgeBase::CategoryContent reads them: the root
#   and a category differ in which scope holds their child categories, not in what reordering means.
#   Both store the mode under the same name, so there is one column to write either way.
class Service::KnowledgeBase::Reorder::Categories < Service::KnowledgeBase::Reorder::Base
  attr_reader :parent

  # @param parent [KnowledgeBase::Category, nil] category whose subcategories are reordered; nil for
  #   the top level, whose mode is stored on the knowledge base itself
  # @param sorting_mode [String, nil] mode to store for that node's categories, as sent by
  #   Gql::Types::Enum::KnowledgeBase::SortingModeType. Nil leaves the stored one alone.
  # @param ordered_ids [Array<Integer>, nil] ids of all categories in the scope, in the wanted
  #   order. Required with the `manual` mode, and refused with an automatic one.
  def initialize(parent: nil, sorting_mode: nil, ordered_ids: nil)
    @parent       = parent
    @sorting_mode = sorting_mode
    @ordered_ids  = ordered_ids
  end

  private

  def node
    parent || active_knowledge_base!
  end

  # `KnowledgeBase::Category.acts_as_list` is scoped to `parent`, so these are exactly the two kinds
  #   of list there are: the children of a category, and the categories with no parent at all.
  def scope
    @scope ||= parent ? parent.children : active_knowledge_base!.categories.root
  end

  # Carried by the knowledge base under the same name as by a category, so the root and a category
  #   are written the same way here.
  def sorting_mode_attribute
    :category_sorting_mode
  end
end

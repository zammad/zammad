# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Sets how the answers listed inside one category are ordered, and stores their hand-made order while
#   that mode is `manual`.
#
# The mode lives on the category, in `answer_sorting_mode` — its own column, so the subcategories of
#   the same category keep whatever mode they were given. The order is the answers' own too
#   (`KnowledgeBase::Answer.acts_as_list` is scoped to `category`).
class Service::KnowledgeBase::Reorder::Answers < Service::KnowledgeBase::Reorder::Base
  attr_reader :category

  # @param category [KnowledgeBase::Category] category whose answers are reordered
  # @param sorting_mode [String, nil] mode to store for that category's answers, as sent by
  #   Gql::Types::Enum::KnowledgeBase::SortingModeType. Nil leaves the stored one alone.
  # @param ordered_ids [Array<Integer>, nil] ids of all answers in the category, in the wanted
  #   order. Required with the `manual` mode, and refused with an automatic one.
  def initialize(category:, sorting_mode: nil, ordered_ids: nil)
    @category     = category
    @sorting_mode = sorting_mode
    @ordered_ids  = ordered_ids
  end

  private

  # `update?` rather than `update_answer?` (the same editor access either way): what is written is a
  #   column of the *category*, plus the positions of the answers filed in it.
  def node
    category
  end

  def scope
    @scope ||= category.answers
  end

  def sorting_mode_attribute
    :answer_sorting_mode
  end
end

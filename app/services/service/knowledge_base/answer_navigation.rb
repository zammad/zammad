# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Calculates navigation only among answers directly below one category. This is
# intentionally distinct from KnowledgeBase::AdjacentAnswer, which traverses
# categories and follows the legacy translation-based visibility rules.
class Service::KnowledgeBase::AnswerNavigation < Service::Base
  Result = Struct.new(:index, :total_count, :previous_answer_id, :next_answer_id, keyword_init: true)

  attr_reader :answer, :locale, :ids

  def initialize(answer:, locale: nil, ids: nil)
    @answer = answer
    @locale = locale
    @ids = ids
  end

  def execute
    sibling_ids = ids || self.sibling_ids
    index = sibling_ids.index(answer.id)
    return if index.nil?

    Result.new(
      index:              index + 1,
      total_count:        sibling_ids.size,
      previous_answer_id: sibling_ids[index - 1],
      next_answer_id:     sibling_ids[(index + 1) % sibling_ids.size],
    )
  end

  private

  def sibling_ids
    Service::KnowledgeBase::Answers
      .with_current_user(current_user)
      .execute(category: answer.category, locale:)
      .except(:includes)
      .pluck(:id)
  end
end

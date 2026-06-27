# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::AdjacentAnswer
  attr_reader :translation, :user

  def initialize(translation, user: nil)
    @translation = translation
    @user        = user
  end

  def next
    sibling_answer(:next) ||
      loop_answers(:next)
  end

  def previous
    sibling_answer(:previous) ||
      sibling_category_answers(current_category, nil, :previous) ||
      loop_answers(:previous)
  end

  private

  def current_category
    @current_category ||= translation.answer.category
  end

  def locale
    @locale ||= translation.kb_locale.system_locale
  end

  def check_category_previous(category)
    apply_answer_scope(category.answers).last || apply_category_scope(category.children)
      .reverse_each
      .lazy
      .filter_map { check_category_previous(it) }
      .first
  end

  def check_category_next(category)
    apply_category_scope(category.children)
      .lazy
      .filter_map { check_category_next(it) }
      .first || apply_answer_scope(category.answers).first
  end

  def apply_answer_scope(scope)
    scope = if user&.permissions?('knowledge_base.editor')
              scope.visible_to_user(user)
            else
              scope.published
            end

    scope.localed(locale).sorted
  end

  def apply_category_scope(scope)
    scope.localed(locale).sorted
  end

  def categories(parent, previous)
    parent&.children || previous.knowledge_base.categories.root
  end

  def apply_position_filter(scope, breakpoint, direction)
    return scope if !breakpoint

    operator = case direction
               when :next
                 '>'
               when :previous
                 '<'
               end

    scope.where("position #{operator} ?", breakpoint.position)
  end

  def sibling_answer(direction)
    scope = apply_position_filter(apply_answer_scope(current_category.answers), translation.answer, direction)

    case direction
    when :next
      scope.first
    when :previous
      scope.last
    end
  end

  def sibling_category_answers(parent_category, breakpoint, direction)
    categories_scope = apply_position_filter(apply_category_scope(categories(parent_category, breakpoint)), breakpoint, direction)
    categories_scope = categories_scope.reverse if direction == :previous

    categories_scope.each do |category|
      answer = case direction
               when :next
                 check_category_next(category)
               when :previous
                 check_category_previous(category)
               end

      return answer if answer.present?
    end

    nil
  end

  def loop_answers(direction)
    current = current_category

    while current
      parent = current.parent

      answer = sibling_category_answers(parent, current, direction)
      return answer if answer.present?

      if direction == :next && parent.present?
        answer = apply_answer_scope(parent.answers).first
        return answer if answer.present?
      end

      current = parent
    end
  end
end

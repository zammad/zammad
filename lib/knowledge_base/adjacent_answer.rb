# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The previous/next links under an answer on the public help site: a walk through the whole tree,
#   in the order the site renders it, so the links agree with the listing they were reached from.
#
# Every list on the way is ordered by the mode the node above it stores for that list — a category's
#   answers by its `answer_sorting_mode`, its subcategories by its `category_sorting_mode`, the top
#   level by the knowledge base's own — through the same scopes
#   KnowledgeBase::Public::BaseController#answers_filter and #categories_filter sort with.
#
# A neighbour is therefore taken by index in the ordered list rather than by comparing `position`:
#   alphabetical and last update are not column comparisons, so there is no "the row after this one"
#   to ask the database for. The same approach Service::KnowledgeBase::AnswerNavigation takes for the
#   desktop view, which is otherwise a different calculation entirely — it never leaves the category.
#
# PERFORMANCE — every step reads a whole sibling list to pick one item out of it, where the
#   `position` cursor this replaced read a single indexed row. Both lists are kept to bare ids
#   (#ordered_answer_ids, #ordered_category_ids) so that only the records actually walked into are
#   ever instantiated, and #first_answer_below abandons a level as soon as one category yields.
#
#   Against the old cursor the cases that cross a category came out well ahead, because it walked
#   sibling *relations* and paid a query per sibling. The shape that is dearer here is a level whose
#   categories are mostly empty: stepping out of a category tries its siblings in turn, and finding a
#   branch empty costs about two queries per category in it. A hundred mostly empty siblings measured
#   around 200ms over some 300 queries.
#
#   A set of "categories holding something for this visitor", consulted before descending, removes
#   that almost entirely — measured at 10ms over 9 queries. It is deliberately not here: building it
#   means reading every category and every visible answer, so its cost follows the size of the
#   knowledge base while the saving follows the emptiness of one branch. Holding the walked branch
#   constant and growing the rest of the knowledge base, it turned a walk from 8ms into 21ms at two
#   hundred unrelated categories. Taxing every walk in a large knowledge base to speed up the few
#   with empty branches is the wrong way round. A version scoped to the subtree being walked would
#   pay; that is the shape to reach for if this ever surfaces in a profile.
#
#   Asking the database for the neighbour alone is possible and was deliberately not done. A sorting
#   mode orders by an expression rather than a column, so stepping in SQL needs a keyset (row-value)
#   predicate or a LAG/LEAD window per mode and per direction — six of them — each having to stay
#   byte-identical to the ORDER BY `sorted_by_mode` builds, or these links start disagreeing with the
#   listing again, which is the one thing this class exists to prevent. It would also not serve the
#   categories, where the walk wants a run of siblings rather than the next one.
#
#   Note that the obvious lazy forms are not available either: `localed` eager-loads the
#   translations, and PostgreSQL rejects `SELECT DISTINCT` with an ORDER BY expression that is not in
#   the select list, so `.first`/`.limit(1)` raise on every mode but `manual` — and `.last` raises
#   ActiveRecord::IrreversibleOrderError, a raw order having nothing to reverse.
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
    answer_by_id(ordered_answer_ids(category).last) ||
      first_answer_below(ordered_category_ids(category).reverse, :previous)
  end

  def check_category_next(category)
    first_answer_below(ordered_category_ids(category), :next) ||
      answer_by_id(ordered_answer_ids(category).first)
  end

  # Walks `category_ids` in the order given and returns the first answer found below one of them.
  #   The single place a category id becomes a record, and lazily, so a level is abandoned as soon as
  #   one of its categories yields something.
  def first_answer_below(category_ids, direction)
    category_ids
      .lazy
      .filter_map { adjacent_answer_in(category_by_id(it), direction) }
      .first
  end

  # The ids of one category's answers as the site lists them: what the visitor may see, translated
  #   into the browsed locale, in that category's own `answer_sorting_mode`.
  #
  # `internal: false` like KnowledgeBase::Public::BaseController#answers_filter — this site never
  #   shows the internal publication date, so it must not order by it either.
  #
  # Ids rather than records, because every caller wants exactly one answer out of the list: the rest
  #   of the category never leaves the database as rows. See #answer_by_id.
  def ordered_answer_ids(category)
    scope = if user&.permissions?('knowledge_base.editor')
              category.answers.visible_to_user(user)
            else
              category.answers.published
            end

    scope
      .localed(locale)
      .sorted_by_mode(category.answer_sorting_mode, system_locale_or_id: locale, internal: false)
      .pluck(:id)
  end

  def answer_by_id(id)
    id && ::KnowledgeBase::Answer.find_by(id: id)
  end

  # The ids of the categories listed inside one node, in the mode that node stores for them. `node`
  #   is a category, or the knowledge base itself at the top level — which has no parent category to
  #   carry the mode and keeps it under the same name.
  #
  # Ids, as #ordered_answer_ids has them: a walk abandons most of a level as soon as one of its
  #   categories yields an answer, so loading the level as records pays for rows nobody looks at.
  #   Measured on a hundred siblings it is the better of the two either way, though only by a tenth —
  #   see the note on the class, which is also where the case this does *not* help is described.
  def ordered_category_ids(node)
    children = node.is_a?(::KnowledgeBase) ? node.categories.root : node.children

    children
      .localed(locale)
      .sorted_by_mode(node.category_sorting_mode, system_locale_or_id: locale)
      .pluck(:id)
  end

  # `find` rather than `find_by`: the id comes from the pluck right above, so a miss is a record
  #   vanishing mid-request — an error to raise, not a "no neighbour" to walk past.
  def category_by_id(id)
    ::KnowledgeBase::Category.find(id)
  end

  def sibling_answer(direction)
    siblings = ordered_answer_ids(current_category)
    index    = siblings.index(translation.answer_id)
    return if index.nil?

    id = case direction
         when :next
           siblings[index + 1]
         when :previous
           siblings[index - 1] if index.positive?
         end

    answer_by_id(id)
  end

  def sibling_category_answers(parent_category, breakpoint, direction)
    first_answer_below(sibling_categories(parent_category, breakpoint, direction), direction)
  end

  # The siblings of `breakpoint` on its own level, in the direction being walked: the ones after it
  #   for `:next`, the ones before it — nearest first — for `:previous`. Without a breakpoint the
  #   whole level is walked, which is how #previous descends into the current category's children.
  #
  # A breakpoint the level does not contain leaves nothing to walk here. It has no translation in the
  #   browsed locale, so the site does not list it on this level either, and an ordered list offers no
  #   index to step from — where the `position` comparison this replaced still had a number to
  #   compare. The caller moves up a level instead, rather than walking a whole level of which half
  #   may lie on the wrong side of the answer being viewed.
  def sibling_categories(parent_category, breakpoint, direction)
    siblings = ordered_category_ids(parent_category || breakpoint.knowledge_base)
    index    = breakpoint && siblings.index(breakpoint.id)

    return [] if breakpoint && index.nil?

    case direction
    when :next
      index ? siblings[(index + 1)..] : siblings
    when :previous
      (index ? siblings[0...index] : siblings).reverse
    end
  end

  def adjacent_answer_in(category, direction)
    case direction
    when :next
      check_category_next(category)
    when :previous
      check_category_previous(category)
    end
  end

  def loop_answers(direction)
    current = current_category

    while current
      parent = current.parent

      answer = sibling_category_answers(parent, current, direction)
      return answer if answer.present?

      if direction == :next && parent.present?
        answer = answer_by_id(ordered_answer_ids(parent).first)
        return answer if answer.present?
      end

      current = parent
    end
  end
end

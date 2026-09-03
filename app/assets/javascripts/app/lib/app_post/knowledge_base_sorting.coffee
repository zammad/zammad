# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# How one list of knowledge base content is ordered: by hand, by title, or most recently updated
#   first, as the sorting mode stored for that list says (`category_sorting_mode` /
#   `answer_sorting_mode`, see KnowledgeBase::SORTING_MODES).
#
# The counterpart of KnowledgeBase::Category.sorted_by_mode and KnowledgeBase::Answer.sorted_by_mode,
#   which order the same two lists for the stacks that render on the server. This interface holds the
#   whole knowledge base as Spine records and never asks the server for a listing, so the order has
#   to be worked out here - and worked out the same way, or the two interfaces disagree about a
#   knowledge base they both show.
#
# Called from the model methods that hand a list out (App.KnowledgeBase#rootCategories,
#   App.KnowledgeBaseCategory#children and #answers) rather than from the views, so nothing that
#   lists content can forget to ask: the reader lists, the editor sidebar and the previous/next links
#   under an answer all read one order.
#
# Two divergences from the server are deliberate. The exact order of two non-ASCII titles is the
#   database's collation to define there and the browser's here, so the two can differ by a hair
#   where an accent or a punctuation mark decides (see the note on `compareTitles`). And an answer is
#   dated for an audience that sees internal content, which is what this interface's reader is - the
#   `internal: true` of KnowledgeBase::Answer.sorted_by_mode.
class App.KnowledgeBaseSorting
  # @param categories [Array<App.KnowledgeBaseCategory>] the categories listed inside one node
  # @param mode [String] that node's `category_sorting_mode`
  # @param kb_locale [App.KnowledgeBaseLocale, undefined] the locale being browsed, which decides
  #   the title and the edit date a record is sorted under. Undefined falls back to the primary
  #   locale, exactly as the displayed title does.
  # @return [Array<App.KnowledgeBaseCategory>] a new array, in the order that node lists them
  @categories: (categories, mode, kb_locale) ->
    ordered categories, mode, kb_locale, categoryTimestamp

  # @param answers [Array<App.KnowledgeBaseAnswer>] the answers filed in one category
  # @param mode [String] that category's `answer_sorting_mode`
  # @param kb_locale [App.KnowledgeBaseLocale, undefined] as above
  # @return [Array<App.KnowledgeBaseAnswer>] a new array, in the order that category lists them
  @answers: (answers, mode, kb_locale) ->
    ordered answers, mode, kb_locale, answerTimestamp

# One list in the mode its node stores for it. The two kinds of list differ only in what dates a
#   record, which is the one thing `timestamp` supplies.
#
# Every mode but the two named ones orders by hand, as the `else` of the two SQL scopes does: an
#   installation whose column holds something this frontend has not heard of still renders a list.
ordered = (items, mode, kb_locale, timestamp) ->
  switch mode
    when 'alphabetical'
      orderedBy items, ((item) -> sortableTitle(item, kb_locale)), compareTitles
    when 'last_update'
      orderedBy items, ((item) -> timestamp(item, kb_locale)), compareRecency
    else
      orderedBy items, ((item) -> item.position), compareAscending

# Decorate, sort, undecorate. The key is worked out once per record rather than on every comparison,
#   because reading the title or the edit date of the translation a record is shown under filters the
#   whole translation collection (App.KnowledgeBaseTranslatable#guaranteedTranslation), which a plain
#   comparator would pay for O(n log n) times.
#
# The id breaks a tie in every mode, as it does in SQL: positions are not unique-constrained, and
#   titles and timestamps can collide just as well.
orderedBy = (items, key, compare) ->
  items
    .map  (item) -> [key(item), item]
    .sort (a, b) -> compare(a[0], b[0]) || a[1].id - b[1].id
    .map  (pair) -> pair[1]

compareAscending = (left, right) ->
  left - right

# `LOWER(title) ASC`: lower-cased before comparing, so two titles differing only in case tie and the
#   id decides between them, and compared with `localeCompare`, which folds an accented letter onto
#   its base one the way a database collation does rather than filing it after "Z" as a codepoint
#   comparison would.
#
# Which collation exactly is the runtime's, not ours - the same freedom the server leaves to the
#   database (see KnowledgeBase::Category.sorted_by_mode).
compareTitles = (left, right) ->
  nullsLast(left, right) ? left.localeCompare(right)

# `DESC NULLS LAST`: newest first, with a record that has no date at all kept off the top rather than
#   sorted as though it were from 1970.
compareRecency = (left, right) ->
  nullsLast(left, right) ? right - left

# What PostgreSQL does with a missing value in either direction: last ascending, and last descending
#   too, which the last-update orders ask for with `NULLS LAST`. Yields null when both sides are
#   there, leaving them to the caller to compare.
nullsLast = (left, right) ->
  return 0  if left is right
  return 1  if !left?
  return -1 if !right?

  null

# The title the interface shows a record under, which is therefore the one it has to sort under. The
#   fallback chain behind it (the browsed locale, then the primary one, then any) is the one
#   KnowledgeBase::Answer.preferred_translation_sql expresses in SQL.
sortableTitle = (item, kb_locale) ->
  shownTranslation(item, kb_locale)?.title?.toLowerCase() ? null

# <the shown translation>.edited_at, as KnowledgeBase::Category.sorted_by_mode dates a category: one
#   editorial timestamp per locale, moved by a title written here or by an edit anywhere below the
#   category, and by nothing else.
#
# `edited_at` rather than `updated_at`, for the same reason it is the answer's date below: the
#   record's own timestamp moves for a reorder, a mode switch and every `touch: true` running up the
#   tree, none of which is an edit of the category.
#
# Through `latest` for its parsing alone - a single date is its own maximum, but a record whose
#   translations are not loaded yet has to come out as null rather than as NaN all the same.
categoryTimestamp = (category, kb_locale) ->
  latest [
    shownTranslation(category, kb_locale)?.edited_at
  ]

# GREATEST(LEAST(internal_at, published_at), <the shown translation>.edited_at), as
#   KnowledgeBase::Answer.sorted_by_mode dates an answer with `internal: true`: this reader shows
#   internally published content, so an answer counts as new from whichever publication came first.
#
# `edited_at` rather than `updated_at`, so adding a tag or moving the answer to another category -
#   which touches the translation row without being an editorial change - does not reorder the list.
answerTimestamp = (answer, kb_locale) ->
  latest [
    earliest [answer.internal_at, answer.published_at]
    shownTranslation(answer, kb_locale)?.edited_at
  ]

# GREATEST and LEAST as PostgreSQL has them: a missing argument is ignored, and the result is missing
#   only when every argument is.
latest = (values) ->
  found = milliseconds(values)
  if found.length then Math.max(found...) else null

earliest = (values) ->
  found = milliseconds(values)
  if found.length then Math.min(found...) else null

# Timestamps reach this interface as the ISO 8601 strings the assets carry and leave as milliseconds,
#   which compare as plain numbers. Anything unparseable is dropped rather than propagated as NaN,
#   which would compare false against everything including itself.
milliseconds = (values) ->
  values
    .map    (value) -> if value? then new Date(value).getTime() else NaN
    .filter (value) -> !isNaN(value)

# A record whose knowledge base or translations are not loaded yet throws on the way to its title -
#   which App.KnowledgeBaseReaderListItem already guards against when rendering one. A list must not
#   fail to appear because one of its records cannot yet say what it is called, so such a record
#   sorts as though it had no title or date, and goes last.
shownTranslation = (item, kb_locale) ->
  try
    item.guaranteedTranslation(kb_locale?.id)
  catch
    undefined

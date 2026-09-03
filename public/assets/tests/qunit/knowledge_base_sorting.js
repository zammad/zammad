// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// How the legacy interface orders one list of knowledge base content: the counterpart of
//   spec/services/service/knowledge_base/answers_spec.rb and the ordering examples in
//   spec/requests/knowledge_base_public/categories_spec.rb, which pin the same three modes for the
//   two stacks that render on the server.
//
// Driven through the model methods every listing goes through (App.KnowledgeBase#rootCategories,
//   App.KnowledgeBaseCategory#children and #answers) rather than through App.KnowledgeBaseSorting
//   directly, because which mode column a list reads is half of what there is to get wrong.

var day = function(number) {
  return '2026-08-' + ('0' + number).slice(-2) + 'T00:00:00.000Z'
}

// One category per mode, so no test has to change a mode another test relies on. Titles are
//   deliberately at odds with the positions: an assertion that passes under either order proves
//   nothing.
window.onload = function() {
  App.KnowledgeBaseLocale.refresh([
    { id: 1, knowledge_base_id: 1, system_locale_id: 1, primary: true },
    { id: 2, knowledge_base_id: 1, system_locale_id: 2, primary: false }
  ])

  App.KnowledgeBase.refresh([
    {
      id: 1,
      active: true,
      iconset: 'FontAwesome',
      kb_locale_ids: [1, 2],
      translation_ids: [],
      // The top level lists categories only, so it carries the category mode alone.
      category_sorting_mode: 'alphabetical'
    }
  ])

  var category = function(id, position, options) {
    return {
      id: id,
      knowledge_base_id: 1,
      parent_id: options.parent_id === undefined ? null : options.parent_id,
      position: position,
      category_icon: 'f115',
      updated_at: options.updated_at || day(1),
      category_sorting_mode: options.categories || 'manual',
      answer_sorting_mode: options.answers || 'manual'
    }
  }

  App.KnowledgeBaseCategory.refresh([
    // The top level categories, which the knowledge base lists alphabetically.
    category(10, 3, { categories: 'manual', answers: 'manual' }),
    category(20, 2, { categories: 'alphabetical', answers: 'alphabetical' }),
    category(30, 1, { categories: 'last_update', answers: 'last_update' }),
    category(40, 0, { categories: 'alphabetical', answers: 'manual' }),
    category(50, 4, { answers: 'alphabetical' }),
    category(60, 5, { answers: 'alphabetical' }),
    category(80, 6, {}),

    // An empty subcategory of 80, which the previous/next walk has to step over on its way to the
    //   answer 80 holds itself.
    category(81, 0, { parent_id: 80 }),

    // 90 lists two subcategories above two answers of its own, which is the whole shape the
    //   previous/next walk has to get right.
    category(90, 7, {}),
    category(91, 0, { parent_id: 90 }),
    category(92, 1, { parent_id: 90 }),

    // Subcategories of 10, listed by hand.
    category(11, 2, { parent_id: 10 }),
    category(12, 0, { parent_id: 10 }),
    category(13, 1, { parent_id: 10 }),

    // Subcategories of 20, listed by title.
    category(21, 0, { parent_id: 20 }),
    category(22, 1, { parent_id: 20 }),
    category(23, 2, { parent_id: 20 }),

    // Subcategories of 30, listed most recently edited first. Their own `updated_at` runs against
    //   that order, because it is not what dates them: only the `edited_at` of the translation each
    //   is shown under does.
    category(31, 0, { parent_id: 30, updated_at: day(9) }),
    category(32, 1, { parent_id: 30, updated_at: day(5) }),
    category(33, 2, { parent_id: 30, updated_at: day(1) }),

    // Subcategories of 40, listed by title while its answers stay hand-arranged.
    category(41, 0, { parent_id: 40 }),
    category(42, 1, { parent_id: 40 })
  ], { clear: true })

  var categoryTranslation = function(id, category_id, title, edited_at) {
    return {
      id: id,
      category_id: category_id,
      kb_locale_id: 1,
      title: title,
      edited_at: edited_at || day(1),
      updated_at: day(1)
    }
  }

  App.KnowledgeBaseCategoryTranslation.refresh([
    categoryTranslation(1, 10, 'Manual'),
    categoryTranslation(2, 20, 'Alphabetical'),
    categoryTranslation(3, 30, 'Recency'),
    categoryTranslation(4, 40, 'Mixed'),
    categoryTranslation(5, 50, 'Ties'),
    categoryTranslation(6, 60, 'Locales'),
    categoryTranslation(8, 80, 'Walk'),
    categoryTranslation(81, 81, 'Empty'),

    categoryTranslation(9, 90, 'Tree'),
    categoryTranslation(91, 91, 'Sub A'),
    categoryTranslation(92, 92, 'Sub B'),

    categoryTranslation(11, 11, 'C'),
    categoryTranslation(12, 12, 'A'),
    categoryTranslation(13, 13, 'B'),

    // Not ASCII: a codepoint comparison would file "Ähre" after "Zebra".
    categoryTranslation(21, 21, 'Zebra'),
    categoryTranslation(22, 22, 'apple'),
    categoryTranslation(23, 23, 'Ähre'),

    categoryTranslation(31, 31, 'One',   day(1)),
    categoryTranslation(32, 32, 'Two',   day(2)),
    categoryTranslation(33, 33, 'Three', day(9)),

    categoryTranslation(41, 41, 'Zebra'),
    categoryTranslation(42, 42, 'Alpha')
  ], { clear: true })

  var answer = function(id, category_id, position, dates) {
    dates = dates || {}

    return {
      id: id,
      category_id: category_id,
      position: position,
      internal_at: dates.internal_at || null,
      published_at: dates.published_at || null,
      archived_at: null,
      translation_ids: [],
      attachments: [],
      tags: []
    }
  }

  App.KnowledgeBaseAnswer.refresh([
    answer(110, 10, 1),
    answer(111, 10, 0),

    answer(210, 20, 0),
    answer(211, 20, 1),

    // Dated by GREATEST(LEAST(internal_at, published_at), edited_at): 311 by its edit, 312 by its
    //   publication, 310 by the earlier of its two publications, 313 by its edit alone (a draft).
    answer(310, 30, 0, { internal_at: day(10), published_at: day(20) }),
    answer(311, 30, 1, { internal_at: day(3),  published_at: day(4) }),
    answer(312, 30, 2, { published_at: day(12) }),
    answer(313, 30, 3, {}),

    answer(410, 40, 0),
    answer(411, 40, 1),

    answer(510, 50, 1),
    answer(511, 50, 0),

    answer(610, 60, 0),
    answer(611, 60, 1),

    answer(800, 80, 0),

    answer(900, 90, 0),
    answer(901, 90, 1),
    answer(910, 91, 0),
    answer(920, 92, 0)
  ], { clear: true })

  var answerTranslation = function(id, answer_id, title, edited_at, kb_locale_id) {
    return {
      id: id,
      answer_id: answer_id,
      kb_locale_id: kb_locale_id || 1,
      title: title,
      edited_at: edited_at || null,
      updated_at: day(1)
    }
  }

  App.KnowledgeBaseAnswerTranslation.refresh([
    answerTranslation(110, 110, 'zulu'),
    answerTranslation(111, 111, 'alpha'),

    answerTranslation(210, 210, 'Zulu'),
    answerTranslation(211, 211, 'alpha'),

    answerTranslation(310, 310, 'One',   day(1)),
    answerTranslation(311, 311, 'Two',   day(15)),
    answerTranslation(312, 312, 'Three', day(2)),
    answerTranslation(313, 313, 'Four',  day(7)),

    answerTranslation(410, 410, 'Zulu'),
    answerTranslation(411, 411, 'Alpha'),

    // Two titles that differ only in case, so the id has to break the tie - and the ids run against
    //   the positions, so a fallback to the hand-made order would show.
    answerTranslation(510, 510, 'apple'),
    answerTranslation(511, 511, 'Apple'),

    // 611 is translated in both locales, 610 in the second one only.
    answerTranslation(610, 610, 'Beta',  null, 2),
    answerTranslation(611, 611, 'Zulu',  null, 1),
    answerTranslation(612, 611, 'Alpha', null, 2),

    answerTranslation(800, 800, 'Walkable'),

    answerTranslation(900, 900, 'First'),
    answerTranslation(901, 901, 'Second'),
    answerTranslation(910, 910, 'In Sub A'),
    answerTranslation(920, 920, 'In Sub B')
  ], { clear: true })
}

var primaryLocale = function() {
  return App.KnowledgeBaseLocale.find(1)
}

var ids = function(records) {
  return records.map(function(record) { return record.id })
}

var childrenOf = function(id, kb_locale) {
  return ids(App.KnowledgeBaseCategory.find(id).children(kb_locale || primaryLocale()))
}

var answersOf = function(id, kb_locale) {
  return ids(App.KnowledgeBaseCategory.find(id).answers(kb_locale || primaryLocale()))
}

QUnit.test('the manual mode lists content in the hand-made order', function(assert) {
  assert.deepEqual(childrenOf(10), [12, 13, 11])
  assert.deepEqual(answersOf(10), [111, 110])
})

QUnit.test('the alphabetical mode lists content by the title it is shown under', function(assert) {
  // "Ähre" folded onto its base letter rather than filed after "Zebra", and "apple" next to
  //   "Alphabetical" rather than after every capital - the same two things the database collation
  //   does for the server-rendered stacks.
  assert.deepEqual(childrenOf(20), [23, 22, 21])
  assert.deepEqual(answersOf(20), [211, 210])
})

QUnit.test('the alphabetical mode breaks a tie on the id, not on the position', function(assert) {
  assert.deepEqual(answersOf(50), [510, 511])
})

QUnit.test('the last update mode lists the most recently updated first', function(assert) {
  // A category is dated by the `edited_at` of the translation it is shown under, and by nothing
  //   else - their own `updated_at` runs the other way here and must not decide.
  assert.deepEqual(childrenOf(30), [33, 32, 31], 'subcategories by the edit date of the translation shown')

  // An answer is dated from whichever publication came first, paired with the edit date of the
  //   translation shown - this reader sees internally published content.
  assert.deepEqual(answersOf(30), [311, 312, 310, 313], 'answers by publication paired with the edit date')
})

QUnit.test('the two lists of one category have a mode each', function(assert) {
  assert.deepEqual(childrenOf(40), [42, 41], 'subcategories by title')
  assert.deepEqual(answersOf(40), [410, 411], 'answers left hand-arranged')
})

QUnit.test('the top level is listed in the mode the knowledge base stores', function(assert) {
  var roots = ids(App.KnowledgeBase.find(1).rootCategories(primaryLocale()))

  // Alphabetical, Locales, Manual, Mixed, Recency, Ties, Tree, Walk - and not one of them in
  //   position order.
  assert.deepEqual(roots, [20, 60, 10, 40, 30, 50, 90, 80])
})

QUnit.test('a list is ordered under the title of the locale being browsed', function(assert) {
  var alternative = App.KnowledgeBaseLocale.find(2)

  // 611 is "Alpha" in the second locale and "Zulu" in the first, so the browsed locale flips the
  //   pair; 610 is untranslated in the first and falls back to the title it is displayed under.
  assert.deepEqual(answersOf(60, alternative), [611, 610])
  assert.deepEqual(answersOf(60, primaryLocale()), [610, 611])
})

QUnit.test('the unordered accessors skip working out an order', function(assert) {
  // Counting, deleting and the emptiness check never look at the order, and must not pay for one -
  //   but they do have to see every record.
  var byId = function(list) { return list.sort(function(a, b) { return a - b }) }
  var category = App.KnowledgeBaseCategory.find(20)

  assert.deepEqual(byId(ids(category.unsortedChildren())), [21, 22, 23])
  assert.deepEqual(byId(ids(category.unsortedAnswers())), [210, 211])
  assert.equal(App.KnowledgeBase.find(1).unsortedRootCategories().length, 8)

  // The bottom of the tree, which is where #deepChildrenIds stops recursing.
  assert.deepEqual(ids(App.KnowledgeBaseCategory.find(11).unsortedChildren()), [])
})

// Reached through the prototype: the controller renders on construction, and none of the walk needs
//   more of it than the answer being viewed and the locale being browsed.
var walkFrom = function(answerId) {
  var paginator = Object.create(App.KnowledgeBaseReaderPagination.prototype)
  paginator.kb_locale = primaryLocale()
  paginator.object = App.KnowledgeBaseAnswer.find(answerId)

  return paginator
}

var nextFrom     = function(answerId) { return walkFrom(answerId).calculateNextAnswer() }
var previousFrom = function(answerId) { return walkFrom(answerId).calculatePreviousAnswer() }

QUnit.test('walking into a category reads it in the mode it is listed in', function(assert) {
  var paginator = walkFrom(210)

  // Into a category listed by title: the first of its answers in that order, not by position.
  assert.equal(paginator.findFirstAnswer(App.KnowledgeBaseCategory.find(20)).id, 211)
  assert.equal(paginator.findlastAnswer(App.KnowledgeBaseCategory.find(20), true).id, 210)

  // Category 80 holds an empty subcategory and an answer of its own. The subcategories come first,
  //   and once they yield nothing the category's own answers have to be reachable - which they were
  //   not while the loop rebound the name it was iterating over.
  assert.equal(paginator.findFirstAnswer(App.KnowledgeBaseCategory.find(80)).id, 800)
})

QUnit.test('the previous/next walk reads a category subcategories first, answers after', function(assert) {
  // A listing shows category 90 as its subcategories 91 and 92, then the two answers it holds
  //   itself - so that is the order the links step through, the one KnowledgeBase::AdjacentAnswer
  //   takes through the same tree for the public help site.
  assert.equal(nextFrom(910).id, 920, 'out of a subcategory into the next one')
  assert.equal(nextFrom(920).id, 900, 'out of the last subcategory into the answers of the parent')
  assert.equal(nextFrom(900).id, 901, 'along the answers of the category')
  assert.equal(nextFrom(901).id, 800, 'and out of the tree into the next one')

  assert.equal(previousFrom(901).id, 900, 'back along the answers')
  assert.equal(previousFrom(900).id, 920, 'back out of the first answer into the last subcategory')
  assert.equal(previousFrom(920).id, 910, 'back into the previous subcategory')
})

QUnit.test('the editor sidebar lists a category in the mode it is browsed in', function(assert) {
  // Both blocks feed the same list to what they render and to the reorder modal, so an editor
  //   rearranges the order they are looking at - whichever mode that order came from.
  var answers = Object.create(App.KnowledgeBaseSidebarAnswers.prototype)
  answers.object = App.KnowledgeBaseCategory.find(20)
  answers.kb_locale = primaryLocale()

  var categories = Object.create(App.KnowledgeBaseSidebarCategories.prototype)
  categories.object = App.KnowledgeBaseCategory.find(20)
  categories.kb_locale = primaryLocale()

  // The ordered lists themselves rather than #items, which maps them through
  //   #attributesForRendering and would drag the whole rendering stack into a unit test.
  assert.deepEqual(ids(answers.answers()), [211, 210])
  assert.deepEqual(ids(categories.categories()), [23, 22, 21])
})

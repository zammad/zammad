class App.KnowledgeBaseReaderPagination extends App.Controller
  constructor: ->
    super
    @render()

  className: 'knowledge-base-article-nav'

  render: ->
    @stopListening()

    previousAnswer = @calculatePreviousAnswer()
    nextAnswer     = @calculateNextAnswer()

    @html App.view('knowledge_base/_reader_pagination')(
      previousAnswer: previousAnswer?.attributesForRendering(@kb_locale)
      nextAnswer:     nextAnswer?.attributesForRendering(@kb_locale)
    )

    for object in [@object, previousAnswer, nextAnswer, @object.category()]
      if object
        @listenTo object, 'refresh', (e) =>
          @render()

  calculatePreviousAnswer: ->
    @calculateSiblingAnswer(-1)

  calculateNextAnswer: ->
    @calculateSiblingAnswer(+1)

  # The same walk KnowledgeBase::AdjacentAnswer takes for the public help site, so the two interfaces
  #   step through a knowledge base in one order: a category is read subcategories first and its own
  #   answers after, because that is how a listing shows it.
  calculateSiblingAnswer: (direction) ->
    if sibling = @calculateSibling(@object.category().answers(@kb_locale), @object, direction)
      return sibling

    # Backing out of the first answer of a category lands in that category's own subcategories - the
    #   listing puts them above the answers, so the last thing in the last of them is what comes
    #   before. Forwards there is nothing to descend into: by the time the answers are being read,
    #   everything below the category has been.
    if direction < 0 and cat_answer = @findlastAnswer(@object.category())
      return cat_answer

    @climbFromCategory(@object.category(), direction)

  # Out of a category and up the tree, one level at a time -
  #   KnowledgeBase::AdjacentAnswer#loop_answers.
  #
  # The climb starts at the category rather than at the answer inside it: what is being left behind
  #   on the first level is the category, and it is that category's siblings that come next. Starting
  #   at the answer made the first step read the answer's *own* subcategories instead, which the
  #   listing had already shown above it.
  climbFromCategory: (category, direction) ->
    while category
      parent = category.parent()

      list = if parent
               parent.children(@kb_locale)
             else
               category.knowledge_base().rootCategories(@kb_locale)

      if siblingAtScope = @findAnswerInSiblingCategory(category, list, direction)
        return siblingAtScope

      # Below the last subcategory of a category come the answers that category holds itself, so
      #   climbing out of that subcategory arrives at them. Forwards only: going back, a category's
      #   own answers come after everything below it, never before.
      if direction > 0 and parent
        if answer = parent.answers(@kb_locale)[0]
          return answer

      category = parent

    null

  calculateSibling: (list, current, direction) ->
    list[@getIndexOf(list, current) + direction]

  getIndexOf: (list, current) ->
    matching = list.filter((elem) -> elem.id == current.id)[0]
    list.indexOf(matching)

  findlastAnswer: (category, include_direct_answers = false) ->
    if include_direct_answers and last_direct = category.answers(@kb_locale).slice(-1)[0]
      return last_direct

    for child in category.children(@kb_locale).reverse()
      if answer = @findlastAnswer(child, true)
        return answer

    return null

  # The subcategories before the category's own answers, as KnowledgeBase::AdjacentAnswer has it: a
  #   listing shows the subcategories above the answers, so walking into the category from outside
  #   arrives at the first subcategory holding something.
  #
  # `child` rather than `category` as the loop variable: CoffeeScript rebinds the name being iterated
  #   over, so reusing it here left the category's own answers unreachable from outside once it had
  #   any subcategory at all.
  findFirstAnswer: (category) ->
    for child in category.children(@kb_locale)
      if answer = @findFirstAnswer(child)
        return answer

    category.answers(@kb_locale)[0]

  findAnswerInSiblingCategory: (category, list, direction) ->
    currentCategoryIndex  = @getIndexOf(list, category)

    categories = if direction < 0
                   list.slice(0, currentCategoryIndex).reverse()
                 else
                   list.slice(currentCategoryIndex + 1)

    for category in categories
      # coffeelint: disable=indentation
      found = if direction < 0
                @findlastAnswer(category, true)
              else
                @findFirstAnswer(category)
      # coffeelint: enable=indentation

      if found
        return found

    null

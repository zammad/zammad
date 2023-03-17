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

  calculateSiblingAnswer: (direction) ->
    if sibling = @calculateSibling(@object.category().answers(), @object, direction)
      return sibling

    if direction < 0 and cat_answer = @findlastAnswer(@object.category())
      return cat_answer

    scope = @object

    while scope
      parent = scope.category?() || scope.parent?()

      list = if parent
               parent.children()
             else
               scope.knowledge_base().rootCategories()

      if siblingAtScope = @findAnswerInSiblingCategory(scope, list, direction)
        return siblingAtScope

      scope = parent

    null

  calculateSibling: (list, current, direction) ->
    list[@getIndexOf(list, current) + direction]

  getIndexOf: (list, current) ->
    matching = list.filter((elem) -> elem.id == current.id)[0]
    list.indexOf(matching)

  findlastAnswer: (category, include_direct_answers = false) ->
    if include_direct_answers and last_direct = category.answers().slice(-1)[0]
      return last_direct

    for category in category.children().reverse()
      if answer = @findlastAnswer(category, true)
        return answer

    return null

  findFirstAnswer: (category) ->
    for category in category.children()
      if answer = @findFirstAnswer(category)
        return answer

    category.answers()[0]

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

class App.KnowledgeBaseSidebarAnswers extends App.KnowledgeBaseSidebarGenericList
  templateName: 'answers'
  title:        __('Answers')
  emptyNote:    __('No answers')

  urlNew: ->
    "#knowledge_base/#{@object.knowledge_base().id}/category/#{@object.id}/answers/new"

  # Its own column, independent of the mode the same category lists its subcategories in.
  sortingMode: ->
    @object.answer_sorting_mode

  # See App.KnowledgeBaseSidebarCategories for what these three are and why they are separate.
  answers: ->
    @answersForMode(@sortingMode())

  answersForMode: (mode) ->
    App.KnowledgeBaseSorting.answers(@object.unsortedAnswers(), mode, @kb_locale)

  itemsForMode: (mode) ->
    @answersForMode(mode)
      .map (elem) =>
        elem.attributesForRendering(@kb_locale, action: 'edit', isEditor: true)

  reorderSaveUrl: ->
    @object.generateURL('reorder_answers')

  newObject: ->
    new App.KnowledgeBaseAnswer(category_id: @object.id)

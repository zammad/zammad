class App.KnowledgeBaseSidebarAnswers extends App.KnowledgeBaseSidebarGenericList
  templateName: 'answers'
  title:        __('Answers')
  emptyNote:    __('No answers')

  urlNew: ->
    "#knowledge_base/#{@object.knowledge_base().id}/category/#{@object.id}/answers/new"

  answers: ->
    @object.answers()

  items: ->
    @answers()
      .sort (a, b) ->
        a.position - b.position
      .map (elem) =>
        elem.attributesForRendering(@kb_locale, action: 'edit', isEditor: true)

  reorderSaveUrl: ->
    @object.generateURL('reorder_answers')

  newObject: ->
    new App.KnowledgeBaseAnswer(category_id: @object.id)

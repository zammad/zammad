class App.KnowledgeBaseSearchController extends App.Controller
  constructor: ->
    super
    @html App.view('knowledge_base/search')(
      knowledge_base: @parentController.getKnowledgeBase()
      kb_locale:      @parentController.kb_locale()
    )

    @searchFieldPanel = new App.KnowledgeBaseSearchFieldPanel(
      el: @$('.js-searchFieldContainer')

      context:     @parentController.getKnowledgeBase()
      kb_locale:   @parentController.kb_locale()
      return_path: @parentController.getKnowledgeBase().uiUrl(@parentController.kb_locale(), 'search')
    )

    if query = @parentController.lastParams.arguments
      @searchFieldPanel.widget.startSearch(query)

    @searchFieldPanel.widget.focus()

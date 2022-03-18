class App.KnowledgeBaseReaderListController extends App.Controller
  constructor: ->
    super
    @render()

    @listenTo App.KnowledgeBase, 'kb_data_change_loaded', @changeLoaded
    @listenTo App.KnowledgeBase, 'kb_visibility_may_have_changed', => @changeLoaded(true)

  changeLoaded: =>
    if !@objectVisibleInternally()
      @parentController.renderNotAvailableAnymore()
      return

    if @renderEmptinessState != @object.isEmpty()
      @render()

  elements:
    '.js-readerListContainer': 'container'

  objectVisibleInternally: ->
    @object.visibleInternally(@parentController.kb_locale())

  render: ->
    if !@parentController.isEditor() && (!@object || !@object.exists() || !@objectVisibleInternally())
      @parentController.renderNotFound()
      return

    @renderEmptinessState = @object.isEmpty()

    if @object.isEmpty()
      @renderScreenPlaceholder(
        icon:   App.Utils.icon('mood-ok')
        detail: __('This category is empty')
        action: if @parentController.isEditor() then __('Start Editing')
        actionCallback: =>
          url = @object.uiUrl(@parentController.kb_locale(), 'edit')
          @navigate url
      )
      return

    @html App.view('knowledge_base/reader_list')()

    @searchFieldPanel = new App.KnowledgeBaseSearchFieldPanel(
      el: @$('.js-searchFieldContainer')

      context:     @object
      kb_locale:   @parentController.kb_locale()
      return_path: @object.uiUrl(@parentController.kb_locale(), 'search-inline')

      willStart: @searchPanelWillStart
      didEnd:    @searchPanelDidEnd
    )

    if @parentController.lastParams.action is 'search-inline'
      @searchFieldPanel.widget.startSearch(@parentController.lastParams.arguments)

    isEditor  = @parentController.isEditor()
    kb_locale = @parentController.kb_locale()

    setTimeout =>
      for kind in ['Categories', 'Answers']
        @container.append new App.KnowledgeBaseReaderListContainer[kind](
          parent:    @object
          isEditor:  isEditor
          kb_locale: kb_locale
        ).el
    , 100

  searchPanelWillStart: =>
    @container.addClass('hide')

  searchPanelDidEnd: =>
    @container.removeClass('hide')

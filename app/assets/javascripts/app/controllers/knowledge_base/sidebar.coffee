class App.KnowledgeBaseSidebar extends App.Controller
  @extend(Spine.Events)

  events:
    'click .js-content-actions-container a': 'contentActionClicked'

  constructor: ->
    super
    @renderedWidgets = []
    @show()

    @controllerBind 'knowledge_base::sidebar::rerender', => @rerender()

    @listenTo App.KnowledgeBase, 'kb_data_change_loaded', =>
      @rerender()
      true

  rerender: =>
    @delay( =>
      @update()
    , 300, 'rerender')

  contentActionClicked: (e) ->
    # coffeelint: disable=indentation
    actionName = switch e.target.dataset.action
                   when 'delete' then 'clickedDelete'
                   when 'visibility' then 'clickedCanBePublished'
                   when 'permissions' then 'clickedPermissions'
    # coffeelint: enable=indentation

    @parentController.bodyModal = @parentController.coordinator[actionName]?(@savedParams)

  update: =>
    for elem in @renderedWidgets
      elem.updateIfNeeded?()

  show: (object, action) ->
    isEdit = action is 'edit'

    @el.toggleClass('hidden', !isEdit)
    @savedParams = object
    @savedAction = action
    @el.empty()

    if !isEdit
      return

    @renderedWidgets = []

    for elem in @getWidgets(object)
      widget = new elem(
        object:           object
        kb_locale:        @parentController.kb_locale()
        parentController: @parentController
      )

      @renderedWidgets.push widget
      @el.append widget.el

  hide: ->
    @el.addClass('hidden')

  getWidgets: (object) ->
    output = [App.KnowledgeBaseSidebarActions]

    if object instanceof App.KnowledgeBase || object instanceof App.KnowledgeBaseCategory
      output.push App.KnowledgeBaseSidebarCategories

    if object instanceof App.KnowledgeBaseCategory
      output.push App.KnowledgeBaseSidebarAnswers

    if object instanceof App.KnowledgeBaseAnswer
      output.push App.KnowledgeBaseSidebarLinkedTickets
      output.push App.KnowledgeBaseSidebarAttachments
      output.push App.KnowledgeBaseSidebarTags

    output

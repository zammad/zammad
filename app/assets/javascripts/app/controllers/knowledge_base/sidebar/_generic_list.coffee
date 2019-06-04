class App.KnowledgeBaseSidebarGenericList extends App.Controller
  className: 'sidebar-block'

  events:
    'click .js-reorder': 'openReorder'
    'click .js-add':     'openAdd'

  constructor: ->
    super

    @html App.view('knowledge_base/sidebar/generic_list')(@templateOptions())

  templateOptions: ->
    iconset:   @object.knowledge_base().iconset
    items:     @items()
    urlNew:    @urlNew()
    enabled:   true
    title:     @title
    emptyNote: @emptyNote

  openReorder: (e) ->
    e.preventDefault()
    e.stopPropagation()

    @parentController.bodyModal = new App.ControllerReorderModal(
      container: @parentController.body
      items:     @items()
      url:       @reorderSaveUrl()
    )

  openAdd: (e) ->
    e.preventDefault()
    e.stopPropagation()

    newObject = @newObject()
    newObject.isFresh = true

    @parentController.bodyModal = new App.KnowledgeBaseAddForm(
      object:           newObject
      container:        @parentController.body
      parentController: @parentController
    )

  newObject: ->
    #has to be overridden

  reorderSaveUrl: ->
    #has to be overridden

  items: ->
    #has to be overridden

  urlNew: ->
    #has to be overridden

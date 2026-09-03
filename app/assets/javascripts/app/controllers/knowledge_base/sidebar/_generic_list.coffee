class App.KnowledgeBaseSidebarGenericList extends App.Controller
  className: 'sidebar-block'

  events:
    'click .js-reorder': 'openReorder'
    'click .js-add':     'openAdd'

  # The modes a knowledge base list can be listed in, as KnowledgeBase::SORTING_MODES has them and
  #   in the order the desktop view offers them (KnowledgeBaseSortingBar.vue). Kept here rather than
  #   in App.ControllerReorderModal, which is generic: what a mode is called and what it looks like
  #   is the knowledge base's business, not the modal's.
  sortingModes: [
    { key: 'alphabetical', label: __('Sort alphabetically'), icon: 'sort-alpha-down' }
    { key: 'manual',       label: __('Sort by drag & drop'), icon: 'rearange' }
    { key: 'last_update',  label: __('Sort by latest updates'),  icon: 'clock' }
  ]

  constructor: ->
    super

    @render()

  render: ->
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
      container:    @parentController.body
      modes:        @sortingModes
      mode:         @sortingMode()
      itemsForMode: (mode) => @itemsForMode(mode)
      url:          @reorderSaveUrl()
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

  # The block and the modal show one list, so both read it through #itemsForMode - the block in the
  #   mode that is stored, the modal in the mode being previewed.
  items: ->
    @itemsForMode(@sortingMode())

  # @return [String] the mode stored for the list this block shows
  sortingMode: ->
    #has to be overridden

  # @param mode [String] the mode to list in, which is not necessarily the stored one
  # @return [Array<Object>] the rendering attributes of that list, in that order
  itemsForMode: (mode) ->
    #has to be overridden

  urlNew: ->
    #has to be overridden

  updateIfNeeded: ->
    @render()

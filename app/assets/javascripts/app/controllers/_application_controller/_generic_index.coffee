class App.ControllerGenericIndex extends App.Controller
  elements:
    '.js-search': 'searchField'

  events:
    'click [data-type=edit]':    'edit'
    'click [data-type=new]':     'new'
    'click [data-type=payload]': 'payload'
    'click [data-type=import]':  'import'
    'click .js-description':     'description'
    'input .js-search': 'search'

  constructor: ->
    super

    @searchQuery        ||= ''
    @dndCallbackOrignal   = @dndCallback

    # set title
    if @pageData.title
      @title @pageData.title, true

    # set nav bar
    if @pageData.navupdate
      @navupdate @pageData.navupdate

    # bind render after a change is done
    if @pageData?.pagerAjax && !@disableRender
      @controllerBind("#{@genericObject}:create #{@genericObject}:update #{@genericObject}:touch #{@genericObject}:destroy", @delayedRender)
    else if !@disableRender
      @subscribeId = App[ @genericObject ].subscribe(@render)

    App[ @genericObject ].bind 'ajaxError', (rec, msg) =>
      @log 'error', 'ajax', msg.status
      if msg.status is 401
        @log 'error', 'ajax', rec, msg, msg.status
        @navigate 'login'

    # execute fetch
    @render()

    # fetch all
    if !@disableInitFetch && !@pageData.pagerAjax
      App[ @genericObject ].fetchFull(
        ->
        clear: true
      )

  show: =>
    if @table
      @table.show()

  hide: =>
    if @table
      @table.hide()

  release: =>
    if @subscribeId
      App[@genericObject].unsubscribe(@subscribeId)

  paginate: (page, params) =>
    search_query = decodeURIComponent(params?.search_query || '')
    return if page is @pageData.pagerSelected && @searchQuery is search_query

    @pageData.pagerSelected = page
    @searchQuery = search_query

    if @table && @searchField.val() isnt search_query
      @searchField.val(search_query)

    @render()

  search: ->
    @delay(
      =>
        @navigate "#{@pageData.pagerBaseUrl}1/#{encodeURIComponent(@searchField.val())}"
    , 300, "#{@controllerId}-render")

  delayedRender: =>
    @delay(@render, 300, "#{@controllerId}-render")

  render: =>
    if @pageData?.objects
      @title @pageData.objects, true

    if @pageData.pagerAjax
      sortBy  = @table?.customOrderBy || @table?.orderBy || @defaultSortBy  || 'id'
      orderBy = @table?.customOrderDirection || @table?.orderDirection || @defaultOrder || 'ASC'

      fallbackSortBy  = sortBy
      fallbackOrderBy = orderBy
      if sortBy isnt 'id'
        fallbackSortBy  = "#{sortBy}, id"
        fallbackOrderBy = "#{orderBy}, ASC"

      @startLoading()

      params = {
        force: true
        refresh: false
        sort_by: fallbackSortBy
        order_by:  fallbackOrderBy
        page: @pageData.pagerSelected
        per_page: @pageData.pagerPerPage
        query: @searchQuery
      }

      active_filters = []
      @$('.tab.active').each( (i,d) ->
        active_filters.push $(d).data('id')
      )

      if @filterCallback
        params = @filterCallback(active_filters, params)

      method = 'indexFull'
      if @searchBar
        method = 'searchFull'

      App[@genericObject][method](
        (collection, data) =>
          @pageData.pagerTotalCount = data.total_count
          if data.total_count > @pageData.pagerPerPage || @searchQuery
            @dndCallback = undefined
          else if @dndCallback is undefined && @dndCallbackOrignal
            @dndCallback       = @dndCallbackOrignal
            @table.renderState = undefined if @table
          @stopLoading()
          @renderObjects(collection)
        params
      )
      return

    objects = App[@genericObject].search(
      sortBy: @defaultSortBy || 'name'
      order:  @defaultOrder
    )
    @renderObjects(objects)

  renderObjects: (objects) =>

    # remove ignored items from collection
    if @ignoreObjectIDs
      objects = _.filter( objects, (item) ->
        return if item.id is 1
        return item
      )

    if !@table

      # show description button, only if content exists
      showDescription = false
      if App[ @genericObject ].description && !_.isEmpty(objects)
        showDescription = true

      @html App.view('generic/admin/index')(
        head:            @pageData.objects
        buttons:         @pageData.buttons
        subHead:         @pageData.subHead
        showDescription: showDescription
        objects:         @pageData.objects
        searchBar:       @searchBar
        searchQuery:     @searchQuery
        filterMenu:      @filterMenu
      )

      @$('.tab').off('click').on(
        'click'
        (e) =>
          e.preventDefault()
          $(e.target).toggleClass('active')
          @delayedRender()
      )

      # show description in content if no no content exists
      if _.isEmpty(objects) && App[ @genericObject ].description
        description = marked(App.i18n.translateContent(App[ @genericObject ].description))
        @$('.table-overview').html(description)
        return

    # append content table
    params = _.extend(
      {
        tableId: "#{@genericObject}-generic-overview"
        el: @$('.table-overview')
        model: App[ @genericObject ]
        objects: objects
        bindRow:
          events:
            click: @edit
        container: @container
        explanation: @pageData.explanation
        groupBy: @groupBy
        dndCallback: @dndCallback
        cloneCallback: @clone
      },
      @pageData.tableExtend
    )

    if @pageData.pagerAjax
      params = _.extend(
        {
          pagerAjax: @pageData.pagerAjax
          pagerBaseUrl: @pageData.pagerBaseUrl
          pagerSelected: @pageData.pagerSelected
          pagerPerPage: @pageData.pagerPerPage
          pagerTotalCount: @pageData.pagerTotalCount
          sortRenderCallback: @render
          searchQuery: @searchQuery
        },
        params
      )

    if !@table
      @table = new App.ControllerTable(params)
    else
      @table.update(objects: objects, pagerSelected: @pageData.pagerSelected, pagerTotalCount: @pageData.pagerTotalCount, dndCallback: @dndCallback, searchQuery: @searchQuery)

    if @pageData.logFacility
      new App.HttpLog(
        el: @$('.page-footer')
        facility: @pageData.logFacility
      )

  editControllerClass: ->
    App.ControllerGenericEdit

  edit: (id, e) =>
    e.preventDefault()
    constructor = @editControllerClass()

    item = App[ @genericObject ].find(id)

    if @editCallback
      @editCallback(item)
      return

    new constructor(
      id:               item.id
      pageData:         @pageData
      genericObject:    @genericObject
      container:        @container
      small:            @small
      large:            @large
      veryLarge:        @veryLarge
      handlers:         @handlers
      validateOnSubmit: @validateOnSubmit
      screen:           @editScreen
      callback: =>
        @resetActiveTabs()
        if @searchQuery
          @navigate "#{@pageData.pagerBaseUrl}"
        else
          @delayedRender()
    )

  newControllerClass: ->
    App.ControllerGenericNew

  new: (e, item) =>
    e?.preventDefault()
    constructor = @newControllerClass()

    new constructor(
      item:             item
      pageData:         @pageData
      genericObject:    @genericObject
      container:        @container
      small:            @small
      large:            @large
      veryLarge:        @veryLarge
      handlers:         @handlers
      validateOnSubmit: @validateOnSubmit
      screen:           @createScreen
      callback: =>
        @resetActiveTabs()
        if @searchQuery
          @navigate "#{@pageData.pagerBaseUrl}"
        else
          @delayedRender()
    )

  clone: (item) =>
    @new(null, item)

  payload: (e) ->
    e.preventDefault()
    new App.WidgetPayloadExample(
      baseUrl: @payloadExampleUrl
      container: @el.closest('.content')
    )

  import: (e) ->
    e.preventDefault()
    @importCallback()

  description: (e) =>
    new App.ControllerGenericDescription(
      description: App[ @genericObject ].description
      container:   @container
    )

  resetActiveTabs: ->
    @$('.tab.active').removeClass('active')

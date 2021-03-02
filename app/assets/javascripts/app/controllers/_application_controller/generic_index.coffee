class App.ControllerGenericIndex extends App.Controller
  events:
    'click [data-type=edit]': 'edit'
    'click [data-type=new]': 'new'
    'click [data-type=payload]': 'payload'
    'click [data-type=import]': 'import'
    'click .js-description': 'description'

  constructor: ->
    super

    # set title
    if @pageData.title
      @title @pageData.title, true

    # set nav bar
    if @pageData.navupdate
      @navupdate @pageData.navupdate

    # bind render after a change is done
    if !@disableRender
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

  paginate: (page) =>
    return if page is @pageData.pagerSelected
    @pageData.pagerSelected = page
    @render()

  render: =>
    if @pageData.pagerAjax
      sortBy  = @table?.customOrderBy || @table?.orderBy || @defaultSortBy  || 'id'
      orderBy = @table?.customOrderDirection || @table?.orderDirection || @defaultOrder || 'ASC'

      fallbackSortBy  = sortBy
      fallbackOrderBy = orderBy
      if sortBy isnt 'id'
        fallbackSortBy  = "#{sortBy}, id"
        fallbackOrderBy = "#{orderBy}, ASC"

      @startLoading()
      App[@genericObject].indexFull(
        (collection, data) =>
          @pageData.pagerTotalCount = data.total_count
          @stopLoading()
          @renderObjects(collection)
        {
          refresh: false
          sort_by: fallbackSortBy
          order_by:  fallbackOrderBy
          page: @pageData.pagerSelected
          per_page: @pageData.pagerPerPage
        }
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
        notes:           @pageData.notes
        buttons:         @pageData.buttons
        menus:           @pageData.menus
        showDescription: showDescription
      )

      # show description in content if no no content exists
      if _.isEmpty(objects) && App[ @genericObject ].description
        description = marked(App[ @genericObject ].description)
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
        },
        params
      )

    if !@table
      @table = new App.ControllerTable(params)
    else
      @table.update(objects: objects, pagerSelected: @pageData.pagerSelected, pagerTotalCount: @pageData.pagerTotalCount)

    if @pageData.logFacility
      new App.HttpLog(
        el: @$('.page-footer')
        facility: @pageData.logFacility
      )

  edit: (id, e) =>
    e.preventDefault()
    item = App[ @genericObject ].find(id)

    if @editCallback
      @editCallback(item)
      return

    new App.ControllerGenericEdit(
      id:            item.id
      pageData:      @pageData
      genericObject: @genericObject
      container:     @container
      small:         @small
      large:         @large
      veryLarge:     @veryLarge
    )

  new: (e) ->
    e.preventDefault()
    new App.ControllerGenericNew(
      pageData:      @pageData
      genericObject: @genericObject
      container:     @container
      small:         @small
      large:         @large
      veryLarge:     @veryLarge
    )

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

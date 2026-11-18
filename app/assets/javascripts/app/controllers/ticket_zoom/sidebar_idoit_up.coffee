class SidebarIdoitUp extends App.Controller
  currentPage: 0
  pageSize:    25

  sidebarItem: =>
    return if !@Config.get('idoit_up_integration')

    isAgentTicketZoom   = (@ticket and @ticket.currentView() is 'agent')
    isAgentTicketCreate = (!@ticket and @taskKey and @taskKey.match('TicketCreateScreen-'))

    return if !isAgentTicketZoom and !isAgentTicketCreate

    @item = {
      name: 'idoit_up'
      badgeIcon: 'idoit-up'
      sidebarHead: __('i-doit up')
      sidebarCallback: @showObjects
      sidebarActions: [
        {
          title:    __('Change Objects')
          name:     'objects-change'
          callback: @changeObjects
        },
      ]
    }
    @item

  changeObjects: =>
    new App.IdoitUpObjectSelector(
      taskKey: @taskKey
      container: @el.closest('.content')
      callback: (objectIds, objectSelectorUi) =>

        # add new objectIds to list of all @objectIds
        # and transfer the complete list to the backend
        @objectIds = @objectIds.concat(objectIds)

        if @ticket && @ticket.id
          @updateTicket(@ticket.id, @objectIds, =>
            objectSelectorUi.close()
            @showObjectsContent()
          )
          return
        objectSelectorUi.close()
        @showObjectsContent()
    )

  showObjects: (el) =>
    @el = el

    # show placeholder
    @objectIds ||= []
    if @ticket && @ticket.preferences && @ticket.preferences.idoit_up && @ticket.preferences.idoit_up.object_ids
      @objectIds = @ticket.preferences.idoit_up.object_ids
    queryParams = @queryParam()
    if queryParams && queryParams.idoit_up_object_ids
      @objectIds.push queryParams.idoit_up_object_ids

    @renderSidebar()

  # render the search form once and keep it separate from the (re-rendered)
  # object list, so typing/searching does not wipe the search field
  renderSidebar: =>
    @currentPage = 0
    @html(App.view('ticket_zoom/sidebar_idoit_up')())

    @el.off('keyup.idoitUp change.idoitUp click.idoitUp')
    @el.on('keyup.idoitUp', 'input.js-searchField', @onSearchChange)
    @el.on('change.idoitUp', '.js-search input.js-shadow', @onSearchChange)
    @el.on('click.idoitUp', '.js-result .js-object', (e) =>
      e.preventDefault()
      @addObject($(e.currentTarget).attr('data-object-id'))
    )
    @el.on('click.idoitUp', '.js-objectList .js-delete', (e) =>
      e.preventDefault()
      @delete($(e.currentTarget).attr('data-object-id'))
    )

    @renderTypeSelect()
    @showObjectsContent()

  renderTypeSelect: =>
    @ajax(
      id:    "idoit-up-object-types-#{@taskKey}"
      type:  'POST'
      url:   "#{@apiPath}/integration/idoit_up"
      data:  JSON.stringify(method: 'cmdb.object_types')
      success: (data, status, xhr) =>
        return if !data.response || !data.response.result
        result = _.sortBy(data.response.result, 'title')
        @el.find('.js-typeSelect').html(@renderTypeSelector(result))
    )

  renderTypeSelector: (result) ->
    options = {}
    for item in result
      options[item.id] = item.title
    return App.UiElement.searchable_select.render(
      name: 'type'
      multiple: false
      limit: 100
      null: false
      nulloption: false
      placeholder: __('Type')
      options: options
    )

  onSearchChange: (e) =>
    params = @formParam(e.target)
    @currentPage = 0
    @lastFilter = params
    @search(params)

  search: (filter) =>
    if _.isEmpty(filter.type) && _.isEmpty(filter.title)
      @lastSearchTermEmpty = true
      @clearResult()
      return

    filter = _.clone(filter)
    if _.isEmpty(filter.type)
      delete filter.type
    if _.isEmpty(filter.title)
      delete filter.title
    else
      filter.title = "%#{filter.title}%" if filter.title.indexOf('%') is -1
    @lastSearchTermEmpty = false

    @ajax(
      id:    "idoit-up-search-#{@taskKey}"
      type:  'POST'
      url:   "#{@apiPath}/integration/idoit_up"
      data:  JSON.stringify(
        method: 'cmdb.objects'
        filter: filter
        limit:  @pageSize
        offset: @currentPage * @pageSize
      )
      success: (data, status, xhr) =>
        return if @lastSearchTermEmpty
        items = data.response?.result || []
        @renderResult(items)

      error: (xhr, status, error) ->
        return if status is 'abort'
    )

  renderResult: (items) =>
    result = App.view('integration/idoit_up_sidebar_result')(
      items:       items
      currentPage: @currentPage
      pageSize:    @pageSize
    )
    @el.find('.js-result').html(result)

    @el.find('.js-result .js-prevPage').on('click', (e) =>
      e.preventDefault()
      return if @currentPage <= 0
      @currentPage -= 1
      @search(@lastFilter) if @lastFilter
    )
    @el.find('.js-result .js-nextPage').on('click', (e) =>
      e.preventDefault()
      @currentPage += 1
      @search(@lastFilter) if @lastFilter
    )

  clearResult: =>
    @el.find('.js-result').empty()

  addObject: (objectId) =>
    objectId = objectId.toString()
    for existingId in @objectIds
      return if existingId.toString() is objectId

    @objectIds = @objectIds.concat([objectId])

    if @ticket && @ticket.id
      @updateTicket(@ticket.id, @objectIds, =>
        @showObjectsContent()
      )
    else
      @showObjectsContent()

    @el.find('input.js-searchField').val('')
    @currentPage = 0
    @lastFilter = null
    @clearResult()

  showObjectsContent: =>

    # show placeholder
    if _.isEmpty(@objectIds)
      @renderList([])
      return

    # ajax call to show items
    @ajax(
      id:    "idoit-up-#{@taskKey}"
      type:  'POST'
      url:   "#{@apiPath}/integration/idoit_up"
      data:  JSON.stringify(method: 'cmdb.objects', filter: ids: @objectIds)
      success: (data, status, xhr) =>
        if data.response
          @renderList(data.response.result)
          return
        @showError(__('Loading failed.'))

      error: (xhr, status, error) =>

        # do not close window if request is aborted
        return if status is 'abort'

        # show error message
        @showError(__('Loading failed.'))
    )

  renderList: (objects) =>
    @el.find('.js-objectList').html(App.view('ticket_zoom/sidebar_idoit_up_objects')(
      objects: objects
    ))

  showError: (message) =>
    @el.find('.js-objectList').html App.i18n.translateInline(message)

  reload: =>
    @showObjectsContent()

  delete: (objectId) =>
    localObjects = []
    for localObjectId in @objectIds
      if objectId.toString() isnt localObjectId.toString()
        localObjects.push localObjectId
    @objectIds = localObjects
    if @ticket && @ticket.id
      @updateTicket(@ticket.id, @objectIds)
    @showObjectsContent()

  postParams: (args) =>
    return if !args.ticket
    return if args.ticket.created_at
    return if !@objectIds
    return if _.isEmpty(@objectIds)
    args.ticket.preferences ||= {}
    args.ticket.preferences.idoit_up ||= {}
    args.ticket.preferences.idoit_up.object_ids = @objectIds

  updateTicket: (ticket_id, objectIds, callback) =>
    App.Ajax.request(
      id:    "idoit-up-update-#{ticket_id}"
      type:  'POST'
      url:   "#{@apiPath}/integration/idoit_up_ticket_update"
      data:  JSON.stringify(ticket_id: ticket_id, object_ids: objectIds)
      success: (data, status, xhr) ->
        if callback
          callback(objectIds)

      error: (xhr, status, details) =>

        # do not close window if request is aborted
        return if status is 'abort'

        # show error message
        @log 'errors', details
        @notify(
          type:    'error'
          msg:     details.error_human || details.error || __('The object could not be updated.')
          timeout: 6000
        )
    )

App.Config.set('501-IdoitUp', SidebarIdoitUp, 'TicketCreateSidebar')
App.Config.set('501-IdoitUp', SidebarIdoitUp, 'TicketZoomSidebar')

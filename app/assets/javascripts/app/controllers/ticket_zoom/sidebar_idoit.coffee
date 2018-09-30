class SidebarIdoit extends App.Controller
  sidebarItem: =>
    return if !@Config.get('idoit_integration')
    @item = {
      name: 'idoit'
      badgeIcon: 'printer'
      sidebarHead: 'i-doit'
      sidebarCallback: @showObjects
      sidebarActions: [
        {
          title:    'Change Objects'
          name:     'objects-change'
          callback: @changeObjects
        },
      ]
    }
    @item

  changeObjects: =>
    new App.IdoitObjectSelector(
      taskKey: @taskKey
      container: @el.closest('.content')
      callback: (objectIds, objectSelectorUi) =>
        if @ticket && @ticket.id

          # add new objectIds to list of all @objectIds
          # and transfer the complete list to the backend
          @objectIds = @objectIds.concat(objectIds)

          @updateTicket(@ticket.id, @objectIds, =>
            objectSelectorUi.close()
            @showObjectsContent(objectIds)
          )
          return
        objectSelectorUi.close()
        @showObjectsContent(objectIds)
    )

  showObjects: (el) =>
    @el = el

    # show placeholder
    @objectIds ||= []
    if @ticket && @ticket.preferences && @ticket.preferences.idoit && @ticket.preferences.idoit.object_ids
      @objectIds = @ticket.preferences.idoit.object_ids
    queryParams = @queryParam()
    if queryParams && queryParams.idoit_object_ids
      @objectIds.push queryParams.idoit_object_ids
    @showObjectsContent()

  showObjectsContent: (objectIds) =>
    if objectIds
      @objectIds = @objectIds.concat(objectIds)

    # show placeholder
    if _.isEmpty(@objectIds)
      @html("<div>#{App.i18n.translateInline('none')}</div>")
      return

    # ajax call to show items
    @ajax(
      id:    "idoit-#{@taskKey}"
      type:  'POST'
      url:   "#{@apiPath}/integration/idoit"
      data:  JSON.stringify(method: 'cmdb.objects', filter: ids: @objectIds)
      success: (data, status, xhr) =>
        if data.response
          @showList(data.response.result)
          return
        @showError('Unable to load data...')

      error: (xhr, status, error) =>

        # do not close window if request is aborted
        return if status is 'abort'

        # show error message
        @showError('Unable to load data...')
    )

  showList: (objects) =>
    list = $(App.view('ticket_zoom/sidebar_idoit')(
      objects: objects
    ))
    list.delegate('.js-delete', 'click', (e) =>
      e.preventDefault()
      objectId = $(e.currentTarget).attr 'data-object-id'
      @delete(objectId)
    )
    @html(list)

  showError: (message) =>
    @html App.i18n.translateInline(message)

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
    args.ticket.preferences.idoit ||= {}
    args.ticket.preferences.idoit.object_ids = @objectIds

  updateTicket: (ticket_id, objectIds, callback) =>
    App.Ajax.request(
      id:    "idoit-update-#{ticket_id}"
      type:  'POST'
      url:   "#{@apiPath}/integration/idoit_ticket_update"
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
          msg:     App.i18n.translateContent(details.error_human || details.error || 'Unable to update object!')
          timeout: 6000
        )
    )

App.Config.set('500-Idoit', SidebarIdoit, 'TicketCreateSidebar')
App.Config.set('500-Idoit', SidebarIdoit, 'TicketZoomSidebar')

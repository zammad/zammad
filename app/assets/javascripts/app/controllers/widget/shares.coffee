class App.WidgetShares extends App.Controller
  events:
    'click .js-edit-share': 'editShare'
    'click .js-delete-share': 'deleteShare'
    'click .js-revoke-share': 'revokeShare'
    'click .js-create-share': 'openShareCreate'

  constructor: ->
    super
    @lastShares = []  # Initialize to prevent undefined errors
    @loadRetryCount = 0
    @isLoadingShares = false
    @shares = []

    # Load ticket object for userGroupAccess method
    if @ticket_id
      @ticket = App.Ticket.findNative(@ticket_id) || App.Ticket.fullLocal(@ticket_id)

    @renderActions()
    
    # Consolidated event handler to prevent multiple reloads
    @controllerBind('Ticket:update Ticket:touch TicketShare:create TicketShare:update TicketShare:destroy OnlineNotification::changed ui::ticket::sidebarRerender', (data) =>
      # Check if this event is for our ticket
      ticket_id = data?.id || data?.share?.ticket_id || data?.ticket_id || data?.ticket?.id
      if ticket_id && @ticket_id && ticket_id.toString() isnt @ticket_id.toString()
        return
      
      # Refresh ticket object for updated permissions
      if @ticket_id
        @ticket = App.Ticket.findNative(@ticket_id) || App.Ticket.fullLocal(@ticket_id)
      
      # Single reload with debounce to prevent blinking
      @scheduleReload(300)
    )

    # Periodic check to ensure data is loaded (fallback for missed events)
    @delay =>
      @ensureDataLoaded()
    , 2000, 'share-data-check'

    @loadShares()
  # Standard reload method called by sidebar system
  reload: (args) =>
    @loadShares()

  # Fallback mechanism to ensure data loads
  ensureDataLoaded: =>
    if !@lastShares || @lastShares.length is 0
      @scheduleReload()

  scheduleReload: (delay = 150) =>
    @delay (=> @loadShares()), delay, 'share-reload'

  loadShares: =>
    return if @isLoadingShares

    @isLoadingShares = true

    # Refresh ticket reference for permission checks, including shared access
    if @ticket_id
      @ticket = App.Ticket.findNative(@ticket_id) || App.Ticket.fullLocal(@ticket_id)
    else
      @isLoadingShares = false
      return

    @loadSharesFromAPI()

  loadSharesFromAPI: =>
    @ajax(
      id:          'load_shares'
      type:        'GET'
      url:         "#{@apiPath}/tickets/#{@ticket_id}/shares"
      processData: true
      success:     @renderShares
      error:       (xhr, status, error) =>
        # Ignore aborted requests
        unless status is 'abort'
          @renderError(xhr, status, error)
      complete:    (xhr, status) =>
        @isLoadingShares = false
        if status is 'abort'
          if (@loadRetryCount ? 0) < 3
            @loadRetryCount = (@loadRetryCount ? 0) + 1
            @delay (=> @loadShares()), 500, 'share-retry'
      )

  renderShares: (data, status, xhr) =>
    shares = data?.shares || []
    @lastShares = shares
    @loadRetryCount = 0
    
    # Refresh local collection with fresh data
    App.TicketShare.refreshForTicket?(@ticket_id, data)
    
    @render(@lastShares)

  renderError: (xhr, status, error) =>
    # Ignore aborted requests caused by view re-renders/navigation
    if status is 'abort' or error is 'abort'
      return
    
    error_message = 'Unable to load shares'
    if xhr?.responseJSON?.error
      error_message = xhr.responseJSON.error
    else if xhr?.statusText
      error_message = "Unable to load shares: #{xhr.statusText}"
    
    @html "<div class='sidebar-block'><div class='alert alert-danger'>#{error_message}</div></div>"

  render: (shares) =>
    # Render the full template with real data
    current_user = App.User.current()
    current_user_id = if current_user then String(current_user.id) else 'unknown'

    @html App.view('widget/shares')(
      shares: shares
      ticket_id: @ticket_id
      current_user_id: current_user_id
    )

  renderActions: =>
    @parentVC?.parentSidebar?.sidebarActionsRender('shares', @parentVC?.item?.sidebarActions || [])

  openShareCreate: (e) =>
    e?.preventDefault()
    new App.TicketShareCreate(
      ticket_id: @ticket_id
      container: @el.closest('.content')
      callback:  => @scheduleReload()
    )


  editShare: (e) =>
    e.preventDefault()
    e.stopPropagation()
    e.stopImmediatePropagation()
    @setCurrentAction('edit')
    
    share_id = $(e.currentTarget).data('share-id')
    # Find current share data from last load
    share = (@lastShares or []).find (s) -> String(s.id) == String(share_id)

    # Safety check - if share not found, try to reload shares first
    unless share
      # Try to reload shares and find the share again
      @ajax(
        id: 'reload_share_for_edit'
        type: 'GET'
        url: "#{@apiPath}/tickets/#{@ticket_id}/shares"
        processData: true
        success: (data, status, xhr) =>
          @lastShares = data?.shares || []
          share = @lastShares.find (s) -> String(s.id) == String(share_id)
          if share
            # Found it after reload, proceed with edit
            new App.TicketShareEdit(
              share: share
              ticket_id: @ticket_id
              container: @el.closest('.content')
              parentWidget: @
              callback: => 
                @loadShares()
            )
          else
            # Still not found, show error
            @notify(
              type: 'error'
              msg: __('Share data not found. Please refresh and try again.')
            )
        error: (xhr, status, error) =>
          @notify(
            type: 'error'
            msg: __('Share data not found. Please refresh and try again.')
          )
      )
      return

    new App.TicketShareEdit(
      share: share
      ticket_id: @ticket_id
      container: @el.closest('.content')
      parentWidget: @
      callback: => 
        @scheduleReload()
    )

  deleteShare: (e) =>
    e.preventDefault()
    e.stopPropagation()
    e.stopImmediatePropagation()
    return if @_requestInFlight
    share_id = $(e.currentTarget).data('share-id')
    @setCurrentAction('delete')

    new App.ControllerConfirm(
      message: __('Are you sure you want to delete this share? This action cannot be undone.'),
      buttonClass: 'btn--danger',
      callback: =>
        @_requestInFlight = true
        @ajax(
          id: 'delete_share'
          type: 'DELETE'
          url: "#{@apiPath}/tickets/#{@ticket_id}/shares/#{share_id}"
          processData: true
          success: (data, status, xhr) =>
            @_requestInFlight = false
            @shareSuccess(data, status, xhr)
          error: (xhr, status, error) =>
            @_requestInFlight = false
            @shareError(xhr, status, error)
          complete: => @_requestInFlight = false
        )
      buttonCancel: true
      container: @el.closest('.content')
    )

  revokeShare: (e) =>
    e.preventDefault()
    e.stopPropagation()
    e.stopImmediatePropagation()
    return if @_requestInFlight
    share_id = $(e.currentTarget).data('share-id')
    @setCurrentAction('revoke')

    @_requestInFlight = true
    @ajax(
      id: 'revoke_share'
      type: 'POST'
      url: "#{@apiPath}/tickets/#{@ticket_id}/shares/#{share_id}/revoke"
      processData: true
      success: (data, status, xhr) =>
        @_requestInFlight = false
        @shareSuccess(data, status, xhr)
      error: (xhr, status, error) =>
        @_requestInFlight = false
        @shareError(xhr, status, error)
      complete: => @_requestInFlight = false
    )


  shareSuccess: (data, status, xhr) =>
    # Get the action type from the AJAX request to show appropriate message
    action = @getCurrentAction()
    if action is 'revoke'
      @notify(type: 'success', msg: __('Share revoked successfully'))
      # Show notification to the shared user that their access has been revoked
      @notifyToSharedUser(data, 'revoked')
    else if action is 'delete'
      @notify(type: 'success', msg: __('Share deleted successfully'))
      # Show notification to the shared user that their access has been removed
      @notifyToSharedUser(data, 'deleted')
    else if action is 'edit'
      @notify(type: 'success', msg: __('Share updated successfully'))
    # Don't show generic success message for edit actions to avoid duplicates
    
    # Reload shares from backend
    @scheduleReload()
    @callback() if @callback
    @clearCurrentAction()

  shareError: (xhr, status, error) =>
    action = @getCurrentAction()
    if action is 'revoke'
      @notify(type: 'error', msg: __('Failed to revoke share'))
    else if action is 'delete'
      @notify(type: 'error', msg: __('Failed to delete share'))
    else
      @notify(type: 'error', msg: __('Failed to update share'))
    @clearCurrentAction()

  getCurrentAction: =>
    @currentAction

  setCurrentAction: (action) =>
    @currentAction = action

  clearCurrentAction: =>
    @currentAction = null

  # Notify the shared user about the action (for deletion/revocation)
  notifyToSharedUser: (data, action) =>
    # Group notifications handled on the server
    return
  refresh: =>
    if @callback
      @callback()

  reload: =>
    @loadShares()






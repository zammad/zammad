class App.WidgetApprovals extends App.Controller
  events:
    'click .js-approve': 'approve'
    'click .js-reject': 'reject'
    'click .js-edit-approval': 'editApproval'
    'click .js-delete-approval': 'deleteApproval'
    'click .js-request-approval': 'openRequestApproval'

  constructor: ->
    super
    @loadRetryCount = 0
    @isLoadingApprovals = false

    # Use passed data or initialize empty array
    if @approvals && @approvals.length > 0
      @approvals = @approvals
      @render(@approvals)
    else
      @approvals = []

    # Use the ticket object passed from sidebar (like core widgets)
    # Fallback to ticket_id for backwards compatibility
    if @object && @object.id
      @ticket = @object
      @ticket_id = @object.id
      @key = "approvals::#{@object_type}::#{@object.id}"
    else if @ticket_id
      @ticket = App.Ticket.findNative(@ticket_id) || App.Ticket.fullLocal(@ticket_id)
      @key = "approvals::Ticket::#{@ticket_id}"

    @renderActions()
    
    # Consolidated event handler to prevent multiple reloads
    @controllerBind('Ticket:update Ticket:touch TicketApproval:create TicketApproval:update TicketApproval:destroy OnlineNotification::changed ui::ticket::sidebarRerender', (data) =>
      # Check if this event is for our ticket
      ticket_id = data?.id || data?.approval?.ticket_id || data?.ticket_id || data?.ticket?.id
      if ticket_id && @ticket_id && ticket_id.toString() isnt @ticket_id.toString()
        return
      
      # Refresh ticket object for updated permissions
      if @ticket_id
        @ticket = App.Ticket.findNative(@ticket_id) || App.Ticket.fullLocal(@ticket_id)
      
      # Single reload with debounce to prevent blinking
      @scheduleReload(300)
    )
    
    # Only load if no data was passed
    unless @approvals && @approvals.length > 0
      @delay =>
        @ensureDataLoaded()
      , 2000, 'approval-data-check'
      @loadApprovals()
  # Standard reload method called by sidebar system
  reload: (args) =>
    if args?.approvals
      @approvals = args.approvals
      @render(@approvals)
    else
      @loadApprovals()

  # Fallback mechanism to ensure data loads
  ensureDataLoaded: =>
    if !@approvals || @approvals.length is 0
      @scheduleReload()

  scheduleReload: (delay = 150) =>
    @delay (=> @loadApprovals()), delay, 'approval-reload'

  loadApprovals: =>
    return if @isLoadingApprovals

    @isLoadingApprovals = true

    # Refresh ticket reference for permission checks, including shared access
    if @ticket_id
      @ticket = App.Ticket.findNative(@ticket_id) || App.Ticket.fullLocal(@ticket_id)
    else
      @isLoadingApprovals = false
      return

    @loadApprovalsFromAPI()

  loadApprovalsFromAPI: =>
    @ajax(
      id:          'load_approvals'
      type:        'GET'
      url:         "#{@apiPath}/tickets/#{@ticket_id}/approvals"
      processData: true
      success:     @renderApprovals
      error:       (xhr, status, error) =>
        # Ignore aborted requests
        unless status is 'abort'
          @renderError(xhr, status, error)
      complete:    (xhr, status) =>
        @isLoadingApprovals = false
        if status is 'abort'
          if (@loadRetryCount ? 0) < 3
            @loadRetryCount = (@loadRetryCount ? 0) + 1
            @delay (=> @loadApprovals()), 500, 'approval-retry'
      )

  renderApprovals: (data, status, xhr) =>
    approvals = data?.approvals || []
    @approvals = approvals
    @loadRetryCount = 0
    
    # Refresh local collection with fresh data
    App.TicketApproval.refreshForTicket?(@ticket_id, data)
    
    @render(@approvals)

  renderError: (xhr, status, error) =>
    # Ignore aborted requests caused by view re-renders/navigation
    if status is 'abort' or error is 'abort'
      return
    
    error_message = 'Unable to load approvals'
    if xhr?.responseJSON?.error
      error_message = xhr.responseJSON.error
    else if xhr?.statusText
      error_message = "Unable to load approvals: #{xhr.statusText}"
    
    @html "<div class='sidebar-block'><div class='alert alert-danger'>#{error_message}</div></div>"

  render: (approvals) =>
    # Render the full template with real data
    current_user = App.User.current()
    current_user_id = if current_user then String(current_user.id) else 'unknown'

    @html App.view('widget/approvals')(
      approvals: approvals
      ticket_id: @ticket_id
      current_user_id: current_user_id
    )

  renderActions: =>
    @parentVC?.parentSidebar?.sidebarActionsRender('approvals', @parentVC?.item?.sidebarActions || [])

  openRequestApproval: (e) =>
    e?.preventDefault()
    new App.TicketApprovalRequest(
      ticket_id: @ticket_id
      container: @el.closest('.content')
      callback:  => @scheduleReload()
    )


  approve: (e) =>
    e.preventDefault()
    approval_id = $(e.currentTarget).data('approval-id')
    @setCurrentAction('approve')
    
    @ajax(
      id: 'approve_approval'
      type: 'POST'
      url: "#{@apiPath}/tickets/#{@ticket_id}/approvals/#{approval_id}/approve"
      processData: true
      success: @approvalSuccess
      error: @approvalError
    )

  reject: (e) =>
    e.preventDefault()
    approval_id = $(e.currentTarget).data('approval-id')
    @setCurrentAction('reject')
    
    @ajax(
      id: 'reject_approval'
      type: 'POST'
      url: "#{@apiPath}/tickets/#{@ticket_id}/approvals/#{approval_id}/reject"
      processData: true
      success: @approvalSuccess
      error: @approvalError
    )

  editApproval: (e) =>
    e.preventDefault()
    e.stopPropagation()
    e.stopImmediatePropagation()
    @setCurrentAction('edit')
    
    approval_id = $(e.currentTarget).data('approval-id')
    
    # Find the approval data
    approval = @approvals?.find (a) -> a.id.toString() == approval_id.toString()
    if approval
      # Create edit modal with current data
      new App.TicketApprovalEdit(
        approval: approval
        ticket_id: @ticket_id
        container: @el.closest('.content')
        callback: => 
          @loadApprovals()
        parentWidget: @
      )
    else
      # Fallback: reload approvals then reopen
      @ajax(
        id: 'reload_approval_for_edit'
        type: 'GET'
        url: "#{@apiPath}/tickets/#{@ticket_id}/approvals"
        processData: true
        success: (data, status, xhr) =>
          @approvals = data?.approvals || []
          approval = @approvals.find (a) -> a.id.toString() == approval_id.toString()
          if approval
            new App.TicketApprovalEdit(
              approval: approval
              ticket_id: @ticket_id
              container: @el.closest('.content')
              callback: => @scheduleReload()
              parentWidget: @
            )
          else
            @notify(type: 'error', msg: __('Approval data not found. Please refresh and try again.'))
        error: (xhr, status, error) =>
          @notify(type: 'error', msg: __('Approval data not found. Please refresh and try again.'))
      )

  deleteApproval: (e) =>
    e.preventDefault()
    e.stopPropagation()
    e.stopImmediatePropagation()
    
    approval_id = $(e.currentTarget).data('approval-id')
    
    # Prevent multiple modals
    return if @__deleteModalOpen
    @__deleteModalOpen = true
    
    # Simple confirmation modal like translation controller
    new App.ControllerConfirm(
      message: __('Are you sure you want to delete this approval request? This action cannot be undone.'),
      buttonClass: 'btn--danger',
      callback: =>
        @setCurrentAction('delete')
        @ajax(
          id: 'delete_approval'
          type: 'DELETE'
          url: "#{@apiPath}/tickets/#{@ticket_id}/approvals/#{approval_id}"
          processData: true
          success: @approvalSuccess
          error: @approvalError
        )
      buttonCancel: true
      container: @el.closest('.content')
    )
    
    # Reset flag after modal is created
    @delay =>
      @__deleteModalOpen = false
    , 100

  approvalSuccess: (data, status, xhr) =>
    # Get the action type from the AJAX request to show appropriate message
    action = @getCurrentAction()
    if action is 'approve'
      @notify(type: 'success', msg: __('Approval request approved successfully'))
    else if action is 'reject'
      @notify(type: 'success', msg: __('Approval request rejected successfully'))
    else if action is 'delete'
      @notify(type: 'success', msg: __('Approval request deleted successfully'))
      # Show notification to the approver that their approval request has been deleted
      @notifyToApprover(data, 'deleted')
    else if action is 'edit'
      @notify(type: 'success', msg: __('Approval request updated successfully'))
    # Don't show generic success message for edit actions to avoid duplicates
    
    # Reload approvals from backend immediately
    @scheduleReload()
    @callback() if @callback
    @clearCurrentAction()

  approvalError: (xhr, status, error) =>
    action = @getCurrentAction()
    if action is 'approve'
      @notify(type: 'error', msg: __('Failed to approve request'))
    else if action is 'reject'
      @notify(type: 'error', msg: __('Failed to reject request'))
    else if action is 'delete'
      @notify(type: 'error', msg: __('Failed to delete approval request'))
    else
      @notify(type: 'error', msg: __('Failed to update approval'))
    @clearCurrentAction()

  getCurrentAction: =>
    @currentAction

  setCurrentAction: (action) =>
    @currentAction = action

  clearCurrentAction: =>
    @currentAction = null

  # Notify the approver about the action (for deletion)
  notifyToApprover: (data, action) =>
    # Find the approval data that was just deleted
    approval_data = data?.approval || data
    return unless approval_data

    approver_id = approval_data.approver_id || approval_data.user_id
    return unless approver_id

    # Get current user to check if we're notifying ourselves
    current_user = App.User.current()
    return if current_user && String(current_user.id) == String(approver_id)

    # Create a notification for the approver
    message = if action is 'deleted'
      __('Your approval request for this ticket has been deleted by %s').replace('%s', current_user?.fullname || __('another user'))
    else
      __('Your approval request for this ticket has been updated by %s').replace('%s', current_user?.fullname || __('another user'))

    # Send notification to the approver via WebSocket
    App.WebSocket.send(
      event: 'notification'
      data:
        user_id: approver_id
        type: 'info'
        message: message
        ticket_id: @ticket_id
        action: action
    )

  refresh: =>
    if @callback
      @callback()

  reload: =>
    @loadApprovals()





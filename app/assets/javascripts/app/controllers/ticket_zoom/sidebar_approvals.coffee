class SidebarApprovals extends App.Controller
  constructor: ->
    super
    @last_can_share = null

    # Ensure taskKey and ticket_id are available for event filtering
    @taskKey = @options.taskKey || @taskKey
    @ticket_id = @options.ticket_id || @ticket?.id || @ticket_id

    # Store ticket reference for later use
    @ticket_ref = @ticket

  sidebarItem: =>
    return if !@canSeeAgentView()
    return if !(@permissionCheck('ticket.agent') or @permissionCheck('admin.*') or @hasShareAccess())

    @item = {
      name: 'approvals'
      badgeIcon: 'checkmark'
      badgeCallback: @badgeRender
      sidebarHead: __('Approvals')
      sidebarCallback: @showPanel
      sidebarActions: []
    }

    if @canShareOrApprove()
      @item.sidebarActions.push(
        title: __('Request Approval')
        name: 'approval-request'
        callback: @requestApproval
      )

    @item

  showPanel: (el) =>
    @elSidebar = el

    # Ensure sidebar is visible before proceeding
    @delay =>
      if @elSidebar && @elSidebar.length > 0 && @elSidebar.is(':visible')
        @proceedWithPanelSetup()
      else
        console.warn "SidebarApprovals - sidebar not visible, retrying for ticket:", @ticket_id
        @delay =>
          @proceedWithPanelSetup()
        , 200, 'approval-panel-visibility-retry'
    , 50, 'approval-panel-visibility-check'

  proceedWithPanelSetup: =>
    if @ticket_id
      @ticket = App.Ticket.fullLocal(@ticket_id) || @ticket
      unless @ticket
        @ajax(
          id:    'load_ticket_for_sidebar'
          type:  'GET'
          url:   "#{@apiPath}/tickets/#{@ticket_id}"
          success: (ticketData) =>
            App.Ticket.refresh([ticketData]) if ticketData?
            @ticket = App.Ticket.findNative(@ticket_id)
            @createApprovalsWidget()
          error: (xhr, status, error) =>
            console.error 'Failed to load ticket for sidebar:', status, error unless status is 'abort'
            @createApprovalsWidget()
        )
        return

    @createApprovalsWidget()

  createApprovalsWidget: =>
    @widget?.destroy?()

    # Ensure we have a valid ticket_id
    current_ticket_id = @ticket_ref?.id || @ticket?.id || @ticket_id

    # Ensure sidebar element is visible before creating widget
    if @elSidebar && @elSidebar.length > 0 && @elSidebar.is(':visible')
      @widget = new App.WidgetApprovals(
        el:       @elSidebar
        ticket_id: current_ticket_id
        parentVC: @
        callback: @refreshApprovals
      )
    else
      # Wait for sidebar to be visible before creating widget
      @delay =>
        if @elSidebar && @elSidebar.length > 0 && @elSidebar.is(':visible')
          @widget = new App.WidgetApprovals(
            el:       @elSidebar
            ticket_id: current_ticket_id
            parentVC: @
            callback: @refreshApprovals
          )
        else
          console.warn "SidebarApprovals - sidebar not visible, skipping widget creation for ticket:", current_ticket_id
      , 200, 'approval-widget-create-retry'

    @loadApprovalsForCheck()

    @delay =>
      if @widget
        @widget.reload()
        @delay =>
          if @widget && @widget.ensureDataLoaded
            @widget.ensureDataLoaded()
        , 500, 'approval-ensure-data'
    , 200, 'approval-panel-show'

  reload: (args) =>
    if @widget && @widget.reload
      @widget.reload(args)
    else if @elSidebar
      @showPanel(@elSidebar)

    @checkAndUpdateActions()

  checkAndUpdateActions: =>
    current_can_share = @canShareOrApprove()
    if @last_can_share isnt current_can_share
      @last_can_share = current_can_share
      @delay =>
        taskKey = @taskKey
        if taskKey
          App.Event.trigger('ui::ticket::sidebarRerender', { taskKey: taskKey, ticket_id: @ticket?.id || @ticket_id })
      , 300, 'update-approvals-actions'

  refreshApprovals: =>
    @showPanel(@elSidebar) if @elSidebar

  loadApprovalsForCheck: =>
    return unless @ticket

    @ajax(
      id: 'load_approvals_for_check'
      type: 'GET'
      url: "#{@apiPath}/tickets/#{@ticket.id}/approvals"
      processData: true
      success: (data, status, xhr) =>
        @approvals = data?.approvals || []
      error: (xhr, status, error) =>
        @approvals = []
    )

  requestApproval: =>
    new App.TicketApprovalRequest(
      ticket_id: @ticket.id
      container: @elSidebar.closest('.content')
      callback: @refreshApprovals
    )

  badgeRender: (el) =>
    @badgeEl = el
    @badgeRenderLocal()

  badgeRenderLocal: =>
    @badgeEl.html(App.view('generic/sidebar_tabs_item')(
      name: 'approvals'
      icon: 'checkmark'
      counter: ''
      counterPossible: false
    ))

  canShareOrApprove: =>
    current_user = App.User.current()
    return false unless current_user
    
    # Admins and agents can always share/approve
    return true if @permissionCheck('admin.*') or @permissionCheck('ticket.agent')
    
    # Check if user is accessing via shares (receivers cannot share/approve)
    return false if @hasShareAccess()
    
    # User is the ticket owner or in the ticket's group
    true

  canSeeAgentView: =>
    return if !@ticket || !@ticket.currentView
    return @ticket.currentView() == 'agent'

  hasShareAccess: =>
    return false unless @ticket
    current_user = App.User.current()
    return false unless current_user
    
    # Check if user has access via shares
    ticket_shares = App.TicketShare.findByAttribute('ticket_id', @ticket.id)
    return false unless ticket_shares
    
    user_groups = current_user.group_ids || []
    share_groups = ticket_shares.map((share) -> share.group_id)
    
    # Check if user belongs to any shared group
    (user_groups & share_groups).length > 0

App.Config.set('450-Approvals', SidebarApprovals, 'TicketZoomSidebar')

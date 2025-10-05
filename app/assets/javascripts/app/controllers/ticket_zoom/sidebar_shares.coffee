class SidebarShares extends App.Controller
  constructor: ->
    super
    @last_can_share = null

    # Ensure taskKey and ticket_id are available for event filtering
    @taskKey = @options.taskKey || @taskKey
    @ticket_id = @options.ticket_id || @ticket?.id || @ticket_id

  sidebarItem: =>
    return if !@canSeeAgentView()
    return if !(@permissionCheck('ticket.agent') or @permissionCheck('admin.*') or @hasShareAccess())

    @item = {
      name: 'shares'
      badgeIcon: 'team'
      badgeCallback: @badgeRender
      sidebarHead: __('Shares')
      sidebarCallback: @showPanel
      sidebarActions: []
    }

    if @canShareOrApprove()
      @item.sidebarActions.push(
        title: __('Share Ticket')
        name: 'share-create'
        callback: @createShare
      )

    @item

  showPanel: (el) =>
    @elSidebar = el

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
            @createSharesWidget()
          error: (xhr, status, error) =>
            console.error 'Failed to load ticket for sidebar:', status, error unless status is 'abort'
            @createSharesWidget()
        )
        return

    @createSharesWidget()

  createSharesWidget: =>
    if @widget
      @widget.destroy?()

    @widget = new App.WidgetShares(
      el:       @elSidebar
      ticket_id: @ticket?.id || @ticket_id
      parentVC: @
      callback: @refreshShares
    )
    
    @delay =>
      if @widget
        @widget.reload()
        @delay =>
          if @widget && @widget.ensureDataLoaded
            @widget.ensureDataLoaded()
        , 500, 'share-ensure-data'
    , 200, 'share-panel-show'

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
      , 300, 'update-shares-actions'

  refreshShares: =>
    @showPanel(@elSidebar) if @elSidebar

  createShare: =>
    new App.TicketShareCreate(
      ticket_id: @ticket.id
      container: @elSidebar.closest('.content')
      callback: @refreshShares
    )

  badgeRender: (el) =>
    @badgeEl = el
    @badgeRenderLocal()

  badgeRenderLocal: =>
    @badgeEl.html(App.view('generic/sidebar_tabs_item')(
      name: 'shares'
      icon: 'team'
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

App.Config.set('451-Shares', SidebarShares, 'TicketZoomSidebar')

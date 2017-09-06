class Edit extends App.ObserverController
  model: 'Ticket'
  observeNot:
    created_at: true
    updated_at: true
  globalRerender: false

  render: (ticket, diff) =>
    defaults = ticket.attributes()
    delete defaults.article # ignore article infos
    taskState = @taskGet('ticket')

    if !_.isEmpty(taskState)
      defaults = _.extend(defaults, taskState)

    new App.ControllerForm(
      elReplace: @el
      model:     App.Ticket
      screen:    'edit'
      handlers:  [
        @ticketFormChanges
      ]
      filter:    @formMeta.filter
      params:    defaults
      #bookmarkable: true
    )

    @markForm(true)

    return if @resetBind
    @resetBind = true
    @bind('ui::ticket::taskReset', (data) =>
      return if data.ticket_id.toString() isnt ticket.id.toString()
      @render(ticket)
    )

class SidebarTicket extends App.Controller
  sidebarItem: =>
    sidebarItem = {
      head:     'Ticket'
      name:     'ticket'
      icon:     'message'
      callback: @editTicket
    }
    if @permissionCheck('ticket.agent')
      sidebarItem['actions'] = [
        {
          title:    'History'
          name:     'ticket-history'
          callback: @showTicketHistory
        },
        {
          title:    'Merge'
          name:     'ticket-merge'
          callback: @showTicketMerge
        },
        {
          title:    'Change Customer'
          name:     'customer-change'
          callback: @changeCustomer
        },
      ]
    sidebarItem

  reload: (args) =>

    # apply tag changes
    if @tagWidget
      if args.tags
        @tagWidget.reload(args.tags)
      if args.tagAdd
        @tagWidget.add(args.tagAdd, args.source)
      if args.tagRemove
        @tagWidget.remove(args.tagRemove)

    # apply link changes
    if @linkWidget && args.links
      @linkWidget.reload(args.links)

  editTicket: (el) =>
    @el = el
    localEl = $( App.view('ticket_zoom/sidebar_ticket')() )

    @edit = new Edit(
      object_id: @ticket.id
      el:        localEl.find('.edit')
      taskGet:   @taskGet
      formMeta:  @formMeta
      markForm:  @markForm
    )

    if @permissionCheck('ticket.agent')
      @tagWidget = new App.WidgetTag(
        el:          localEl.filter('.tags')
        object_type: 'Ticket'
        object:      @ticket
        tags:        @tags
      )
      @linkWidget = new App.WidgetLink(
        el:          localEl.filter('.links')
        object_type: 'Ticket'
        object:      @ticket
        links:       @links
      )
      @timeUnitWidget = new App.TicketZoomTimeUnit(
        el:        localEl.filter('.js-timeUnit')
        object_id: @ticket.id
      )
    @html localEl

  showTicketHistory: =>
    new App.TicketHistory(
      ticket_id: @ticket.id
      container: @el.closest('.content')
    )

  showTicketMerge: =>
    new App.TicketMerge(
      ticket:    @ticket
      task_key:  @task_key
      container: @el.closest('.content')
    )

  changeCustomer: =>
    new App.TicketCustomer(
      ticket_id: @ticket.id
      container: @el.closest('.content')
    )

App.Config.set('100-TicketEdit', SidebarTicket, 'TicketZoomSidebar')

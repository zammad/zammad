class App.TicketZoomMeta extends App.ControllerObserver
  @extend App.PopoverProvidable
  @registerPopovers 'Escalation', 'TicketReferences'
  events:
    'click .ticket-number-copy > .ticketNumberCopy-icon': 'copyTicketNumber'
    'click .js-checklist-state': 'openChecklist'

  model: 'Ticket'
  observe:
    number: true
    created_at: true
    updated_at: true
    escalation_at: true

  render: (ticket) =>
    @last_ticket = ticket

    if App.Config.get('checklist')
      @checklistState      = App.Checklist.calculateState(ticket)
      @checklistReferences = App.Checklist.calculateReferences(ticket)

    @html App.view('ticket_zoom/meta')(
      ticket:              ticket
      isCustomer:          ticket.currentView() is 'customer'
      checklistState:      @checklistState
      checklistReferences: @checklistReferences
    )

    @$('.ticket-references-popover').data('tickets', @checklistReferences)
    @renderPopovers()

    @controllerUnbind('ui::ticket::all::loaded', @updateOnTicketAllLoaded)
    @controllerBind('ui::ticket::all::loaded', @updateOnTicketAllLoaded)

  updateOnTicketAllLoaded: (data) =>
    return if data.ticket_id.toString() isnt @last_ticket.id.toString()

    state      = App.Checklist.calculateState(@last_ticket)
    references = App.Checklist.calculateReferences(@last_ticket)

    return if @checklistState == state && @checklistReferences == references

    @render(@last_ticket)

  copyTicketNumber: =>
    text = @el.find('.js-objectNumber').first().data('number') || ''
    if text
      @copyToClipboardWithTooltip(text, '.ticket-number-copy', '.main')

  openChecklist: =>
    @el
      .closest('.content')
      .find(".tabsSidebar-tab[data-tab='checklist']:not(.active)")
      .click()


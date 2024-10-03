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
    checklist_total: true
    checklist_incomplete: true

  render: (ticket) =>
    if App.Config.get('checklist')
      checklistState      = App.Checklist.calculateState(ticket)
      checklistReferences = App.Checklist.calculateReferences(ticket)


    @html App.view('ticket_zoom/meta')(
      ticket:              ticket
      isCustomer:          ticket.currentView() is 'customer'
      checklistState:      checklistState
      checklistReferences: checklistReferences
    )

    @$('.ticket-references-popover').data('tickets', checklistReferences)
    @renderPopovers()

  copyTicketNumber: =>
    text = @el.find('.js-objectNumber').first().data('number') || ''
    if text
      @copyToClipboardWithTooltip(text, '.ticket-number-copy', '.main')

  openChecklist: =>
    @el
      .closest('.content')
      .find(".tabsSidebar-tab[data-tab='checklist']:not(.active)")
      .click()


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
    escalation_at: true

  constructor: ->
    super
    App.ChecklistItem.subscribe(@checklistItemsChanged)
    @subscribeToChecklistTickets()

  checklistItemsChanged: =>
    @subscribeToChecklistTickets()
    @forceRerender()

  checklistTicketChanged: =>
    @forceRerender()

  forceRerender: =>
    @render(App[@model].fullLocal(@object_id))

  subscribeToChecklistTickets: =>
    if @checklistTicketsSubscriptions
      for id, key in @checklistTicketsSubscriptions
        App.Ticket.unsubscribeItem(id, key)

    @checklistTicketsSubscriptions = undefined

    checklist = App.Checklist.findByAttribute('ticket_id', @object_id)

    return if !checklist

    @checklistTicketsSubscriptions = checklist
      .sorted_items()
      .filter (elem) -> elem.ticket_id
      .map (elem) => [elem.ticket_id, App.Ticket.subscribeItem(elem.ticket_id, @checklistTicketChanged)]

  render: (ticket) =>
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


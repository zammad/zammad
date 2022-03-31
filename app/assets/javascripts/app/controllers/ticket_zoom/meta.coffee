class App.TicketZoomMeta extends App.ControllerObserver
  @extend App.PopoverProvidable
  @registerPopovers 'Escalation'
  events:
    'click .ticket-number-copy': 'copyTicketNumber'

  model: 'Ticket'
  observe:
    number: true
    created_at: true
    escalation_at: true

  render: (ticket) =>
    @html App.view('ticket_zoom/meta')(
      ticket:     ticket
      isCustomer: ticket.currentView() is 'customer'
    )
    @renderPopovers()

  copyTicketNumber: =>
    text = $('.active.content .js-objectNumber').first().data('number') || ''
    if text
      clipboard.copy(text)

      tooltipCopied = @el.find('.ticket-number-copy').tooltip(
        trigger:    'manual'
        html:       true
        animation:  true
        delay:      0
        placement:  'bottom'
        container:  '.main'
        title: ->
          App.i18n.translateContent('Copied to clipboard!')
      )
      tooltipCopied.tooltip('show')
      @delay( ->
        tooltipCopied.tooltip('hide')
      , 1500)

class TicketReferences extends App.PopoverProvider
  @klass = App.Ticket
  @selectorCssClassPrefix = 'ticket-references'
  @templateName = 'ticket_references'
  @includeData = false

  buildTitleFor: (elem) ->
    App.i18n.translateInline('Tracked as checklist item in')

  buildContentFor: (elem) ->
    @buildHtmlContent(
      ticketList: App.view('generic/ticket_list')(
        tickets: $(elem).data('tickets')
        show_id: true
      )
    )

App.PopoverProvider.registerProvider('TicketReferences', TicketReferences)

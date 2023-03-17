class Ticket extends App.SingleObjectPopoverProvider
  @klass = App.Ticket
  @selectorCssClassPrefix = 'ticket'
  @templateName = 'ticket'
  @includeData = false

  displayTitleUsing: (object) ->
    object.title

App.PopoverProvider.registerProvider('Ticket', Ticket)

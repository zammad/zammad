class Escalation extends App.SingleObjectPopoverProvider
  @klass = App.Ticket
  @selectorCssClassPrefix = 'escalation'
  @templateName = 'escalation'
  @includeData = false

  displayTitleUsing: (object) ->
    App.i18n.translateInline('Escalation Times')

  buildContentFor: (elem) ->
    id = @objectIdFor(elem)
    object = @constructor.klass.fullLocal(id)

    @buildHtmlContent(
      object: object
    )

App.PopoverProvider.registerProvider('Escalation', Escalation)

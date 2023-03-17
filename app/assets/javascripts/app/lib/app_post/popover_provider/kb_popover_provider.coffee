class App.KbPopoverProvider extends App.SingleObjectPopoverProvider
  @templateName = 'kb_generic'
  @includeData = false
  displayTitleUsing: (object) ->
    object.title

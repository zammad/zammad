class App.ControllerGenericDescription extends App.ControllerModal
  buttonClose: true
  buttonCancel: false
  buttonSubmit: __('Close')
  head: __('Description')

  content: =>
    marked(App.i18n.translateContent(@description))

  onSubmit: =>
    @close()

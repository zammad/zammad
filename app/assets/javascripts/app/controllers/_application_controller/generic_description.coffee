class App.ControllerGenericDescription extends App.ControllerModal
  buttonClose: true
  buttonCancel: false
  buttonSubmit: 'Close'
  head: 'Description'

  content: =>
    marked(App.i18n.translateContent(@description))

  onSubmit: =>
    @close()

class App.ImportResult extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: 'Close'
  autoFocusOnFirstInput: false
  head: 'Import'
  large: true
  templateDirectory: 'generic/object_import/'

  content: =>

    content = $(App.view("#{@templateDirectory}/imported")(
      head: 'Imported'
      result: @result
    ))
    content

  onSubmit: (e) =>
    @close()

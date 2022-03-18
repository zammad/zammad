class App.ImportResult extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Close')
  autoFocusOnFirstInput: false
  head: __('Import')
  large: true
  templateDirectory: 'generic/object_import/'

  content: =>

    content = $(App.view("#{@templateDirectory}/imported")(
      head: __('Imported')
      result: @result
    ))
    content

  onSubmit: (e) =>
    @close()

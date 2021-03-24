class App.ControllerGenericDestroyConfirm extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: 'delete'
  buttonClass: 'btn--danger'
  head: 'Confirm'
  small: true

  content: ->
    App.i18n.translateContent('Sure to delete this object?')

  onSubmit: =>
    options = @options || {}
    options.done = =>
      @close()
      if @callback
        @callback()
    options.fail = (xhr, data) =>
      @log 'errors'
      @showAlert(data.human_error || data.error)
    @item.destroy(options)

class App.ControllerConfirm extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: 'yes'
  buttonClass: 'btn--danger'
  head: 'Confirm'
  small: true

  content: ->
    App.i18n.translateContent(@message)

  onSubmit: =>
    @close()
    if @callback
      @callback()

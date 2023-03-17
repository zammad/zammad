class App.ControllerGenericDestroyConfirm extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('delete')
  buttonClass: 'btn--danger'
  head: __('Confirmation')
  small: true

  content: ->
    App.i18n.translateContent('Do you really want to delete this object?')

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

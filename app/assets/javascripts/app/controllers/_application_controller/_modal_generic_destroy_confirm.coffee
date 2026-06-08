class App.ControllerGenericDestroyConfirm extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Delete')
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
      if data?.unprocessable_content
        @showAlert(App.i18n.translatePlain(data.error_human, data.unprocessable_content...))
      else
        @showAlert(data.error_human or data.error)
    @item.destroy(options)

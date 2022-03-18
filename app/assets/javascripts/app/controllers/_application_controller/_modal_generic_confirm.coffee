class App.ControllerConfirm extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Yes')
  buttonClass: 'btn--danger'
  head: __('Confirmation')
  small: true

  content: ->
    App.i18n.translateContent(@message)

  onSubmit: =>
    @close()
    if @callback
      @callback()

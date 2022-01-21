class App.ControllerErrorModal extends App.ControllerModal
  buttonClose: true
  buttonCancel: false
  buttonSubmit: __('Close')
  #buttonClass: 'btn--danger'
  head: __('Error')
  #small: true
  #shown: true
  showTrySupport: true

  content: ->
    @message

  onSubmit: =>
    @close()
    if @callback
      @callback()

class App.ErrorModal extends App.ControllerModal
  buttonClose: true
  buttonCancel: false
  buttonSubmit: 'Close'
  #buttonClass: 'btn--danger'
  head: 'Error'
  #small: true
  #shown: true
  showTrySupport: true

  content: ->
    @message

  onSubmit: =>
    @close()
    if @callback
      @callback()

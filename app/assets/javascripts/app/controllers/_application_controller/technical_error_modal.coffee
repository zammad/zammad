class App.ControllerTechnicalErrorModal extends App.ControllerModal
  head:         "StatusCode: #{status}"
  contentCode:  ''
  buttonClose:  false
  buttonSubmit: 'Ok'
  onSubmit:     (e) -> @close(e)

  content: ->
    "<pre><code>#{@contentCode}</code></pre>"

class App.CustomerChatImageView extends App.ControllerModal
  buttonClose: true
  buttonCancel: false
  buttonSubmit: 'Download'
  buttonClass: 'btn--success'
  head: ''
  dynamicSize: true

  content: ->
    "<div class=\"centered imagePreview\"><img style=\"max-width: 100%; width: 1000px;\" src=\"#{@image_base64}\"></div>"

  onSubmit: =>
    downloadLink = document.createElement('a')
    downloadLink.href = @image_base64
    downloadLink.target = '_blank'
    downloadLink.download = 'chat_message_image'
    downloadLink.click()

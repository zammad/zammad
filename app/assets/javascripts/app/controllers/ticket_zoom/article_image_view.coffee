class App.TicketZoomArticleImageView extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: 'Download'
  buttonClass: 'btn--success'
  head: ''
  large: true

  events:
    'submit form':      'submit'
    'click .js-cancel': 'cancel'
    'click .js-close':  'cancel'

  content: ->
    "<div class=\"centered\">#{@image}</div>"

  onSubmit: =>
    url = "#{$(@image).attr('src')}?disposition=attachment"
    window.open(url, '_blank')

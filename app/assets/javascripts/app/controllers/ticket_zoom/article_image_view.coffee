class App.TicketZoomArticleImageView extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: 'Download'
  buttonClass: 'btn--success'
  head: ''
  veryLarge: true

  events:
    'submit form':      'submit'
    'click .js-cancel': 'cancel'
    'click .js-close':  'cancel'

  constructor: ->
    super
    @unbindAll()
    $(document).bind('keydown.image_preview', 'right', (e) =>
      nextElement = @parentElement.closest('.attachment').next('.attachment.attachment--preview')
      return if nextElement.length is 0
      @close()
      nextElement.find('img').click()
    )
    $(document).bind('keydown.image_preview', 'left', (e) =>
      prevElement = @parentElement.closest('.attachment').prev('.attachment.attachment--preview')
      return if prevElement.length is 0
      @close()
      prevElement.find('img').click()
    )

  content: ->
    @image = @image.replace(/view=preview/, 'view=inline')
    "<div class=\"centered imagePreview\">#{@image}</div>"

  onSubmit: =>
    @image = @image.replace(/(\?|)view=(preview|inline)/, '')
    url = "#{$(@image).attr('src')}?disposition=attachment"
    window.open(url, '_blank')

  onClose: =>
    @unbindAll()

  unbindAll: ->
    $(document).unbind('keydown.image_preview')

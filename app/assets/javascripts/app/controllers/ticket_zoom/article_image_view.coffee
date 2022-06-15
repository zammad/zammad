class App.TicketZoomArticleImageView extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Download')
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
    $(document).on('keydown.image_preview', (e) =>
      return @nextRight() if e.keyCode is 39 # right
      return @nextLeft() if e.keyCode is 37 # left
    )

  nextRight: =>
    nextElement = @parentElement.closest('.attachment').next('.attachment.attachment--preview')
    return if nextElement.length is 0
    @close()
    nextElement.find('img').trigger('click')

  nextLeft: =>
    prevElement = @parentElement.closest('.attachment').prev('.attachment.attachment--preview')
    return if prevElement.length is 0
    @close()
    prevElement.find('img').trigger('click')

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
    $(document).off('keydown.image_preview')

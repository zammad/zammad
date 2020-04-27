class App.UiElement.richtext.additions.RichTextToolPopupVideo extends App.UiElement.richtext.additions.RichTextToolPopup
  labelNew:      'Insert'
  labelExisting: 'Replace'

  @regexps: {
    youtube: [
      /youtube.com\/watch\?v=(\S[^:#?&/]+)/
      /youtu.be\/(\S[^:#?&/]+)/
      /youtube.com\/embed\/(\S[^:#?&/]+)/
    ],
    vimeo: [
      /vimeo.com\/([\w]+)/
    ]
  }

  @detectProviderAndId: (input) =>
    return if !input

    output = null

    for provider, regexps of @regexps
      for regexp in regexps
        if result = input.match(regexp)
          return [provider, result[1]]

  @urlToMarkup: (input) ->
    parsed = @detectProviderAndId(input)

    return if !parsed

    "( widget: video, provider: #{parsed[0]}, id: #{parsed[1]} )"

  apply: (callback) ->
    input  = @el.find('input').val()
    markup = @constructor.urlToMarkup(input)

    if !markup
      new App.ControllerErrorModal(
        message: 'Invalid video URL'
      )

      return

    @insertVideo(markup)
    callback()

  insertVideo: (markup) ->
    textEditor = $(@event.currentTarget).closest('.richtext.form-control').find('[contenteditable]')

    switch @selection.type
      when 'existing'
        @selection.dom.text(markup)
      when 'append'
        newElem = document.createTextNode(markup)
        @selection.dom.append(newElem)
      when 'caret'
        newElem = document.createTextNode(markup)

        surroundingDom = @selection.dom[0]

        if surroundingDom instanceof Text
          @selection.dom[0].splitText(@selection.offset)

        $(newElem).insertAfter(@selection.dom)
      when 'range'
        newElem = document.createTextNode(markup)

        placeholder = textEditor.find('span.highlight-emulator')

        placeholder.empty()
        placeholder.append(newElem)

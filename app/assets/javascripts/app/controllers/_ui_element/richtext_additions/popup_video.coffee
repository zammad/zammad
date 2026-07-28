class App.UiElement.richtext.additions.RichTextToolPopupVideo extends App.UiElement.richtext.additions.RichTextToolPopup
  labelNew:      __('Insert element')
  labelExisting: __('Replace element')
  labelClear:    null

  didInitialize: ->
    super

    public_video_servers     = ['Youtube', 'Vimeo']
    self_hosted_video_server = App.Config.get('kb_self_hosted_video_servers')
      .map (server) -> server.name
      .sort((a, b) -> a.localeCompare(b))

    $('<div>')
      .addClass('help-block js-providers-list')
      .text(public_video_servers.concat(self_hosted_video_server).join(', '))
      .appendTo(@el)

    $('<div>')
      .addClass('help-block danger-color js-errors')
      .appendTo(@el)

  # Built-in providers are recognized purely by their (fixed) URL.
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

  # Self-hosted providers can live on any (admin-whitelisted) host, so the
  # provider is determined by matching the pasted URL's host against the
  # configured server whitelist; the id is then extracted from the path/query.
  @selfHostedRegexps: {
    peertube: [
      /\/w\/([\w-]+)/
      /\/videos\/(?:watch|embed)\/([\w-]+)/
    ],
    mediacms: [
      /[?&]m=([\w-]+)/
    ]
  }

  @detectProviderAndId: (input) =>
    return if !input

    for provider, regexps of @regexps
      for regexp in regexps
        if result = input.match(regexp)
          return { provider: provider, id: result[1] }

    @detectSelfHosted(input)

  @detectSelfHosted: (input) ->
    host = @hostFromUrl(input)
    return if !host

    for provider, regexps of @selfHostedRegexps
      for regexp in regexps
        if result = input.match(regexp)
          return { provider: provider, id: result[1], host: host }

  @hostFromUrl: (input) ->
    for candidate in [input, "https://#{input}"]
      try
        return new URL(candidate).host
      catch
        continue

  urlToMarkup: (input) ->
    parsed = @constructor.detectProviderAndId(input)

    if !parsed
      @applyError(__('Invalid video URL'))
      return

    if !parsed.host
      return "( widget: video, provider: #{parsed.provider}, id: #{parsed.id} )"

    hostAllowed = _.some(App.Config.get('kb_self_hosted_video_servers'), (server) -> server.host == parsed.host)

    if !hostAllowed
      @applyError(__('Video server not allowed. Please add to the list of allowed video servers.'))
      return

    "( widget: video, provider: #{parsed.provider}, host: #{parsed.host}, id: #{parsed.id} )"

  apply: (callback) ->
    input  = @el.find('input').val()
    markup = @urlToMarkup(input)

    if !markup
      return

    @insertVideo(markup)
    callback()

  applyError: (error) ->
    @el.find('.js-errors').text(error)
    @el.find('.js-providers-list').hide()
    @el.find('input[name=link]').addClass('has-error')

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

class App.UiElement.richtext.additions.RichTextToolPopupLink extends App.UiElement.richtext.additions.RichTextToolPopup
  formParams: (params) ->
    # coffeelint: disable=indentation
    url = if params.selection.type is 'existing' && !params.selection.dom.attr('data-target-type')?
            params.selection.dom.attr('href')
    # coffeelint: enable=indentation

    link: url

  applyOnto: (dom, url, text = null) ->
    dom
      .attr('href', url)
      .removeAttr('data-target-id')
      .removeAttr('data-target-type')

    if text?
      dom.text(text)

    dom

  ensureProtocol: (input) ->
    input = input.trim()

    if @isWithProtocol(input) || @isRelativePath(input) || @isMailto(input)
      input
    else
      'http://' + input

  apply: (callback) ->
    input = @el.find('input').val()
    url = @ensureProtocol(input)

    textEditor = $(@event.currentTarget).closest('.richtext.form-control').find('[contenteditable]')

    switch @selection.type
      when 'existing'
        @applyOnto(@selection.dom, url)
      when 'append'
        newElem = $('<a>')
        @applyOnto(newElem, url, input)
        @selection.dom.append(newElem)
      when 'caret'
        newElem = $('<a>')
        @applyOnto(newElem, url, input)
        @selection.dom[0].splitText?(@selection.offset)
        newElem.insertAfter(@selection.dom)
      when 'range'
        placeholder = textEditor.find('span.highlight-emulator')
        newElem = $('<a>')
        @applyOnto(newElem, url)
        placeholder.wrap(newElem)
        placeholder.contents()

    callback()

  clear: ->
    switch @selection.type
      when 'existing'
        $(@selection.dom).contents().unwrap()

  isWithProtocol: (input) ->
    /^\S+\:\/\//.test(input)

  isMailto: (input) ->
    /^mailto\:\S+@\S/.test(input)

  isRelativePath: (input) ->
    input[0] is '/'

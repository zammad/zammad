# coffeelint: disable=camel_case_classes
class App.UiElement.tag
  @render: (attributeConfig) ->
    attribute = $.extend(true, {}, attributeConfig)
    initialValue = attribute.value || '' # Initial value to preserve

    if !attribute.id
      attribute.id = 'tag-' + new Date().getTime() + '-' + Math.floor(Math.random() * 999999)
    item = $( App.view('generic/input')(attribute: attribute) )
    source = "#{App.Config.get('api_path')}/tag_search"
    possibleTags = {}
    a = ->
      fieldName = '#' + attribute.id
      field = $(fieldName)

      isFocused = field.is(':focus')

      # Compare the original value with the current input while typing
      # to correctly create labels and distinguish existing ones from newly added labels.
      val = field.val()
      if val?.startsWith(initialValue)
        addedValue = val.slice(initialValue.length)
      field.val(initialValue)

      field.tokenfield(
        createTokensOnBlur: true
        showAutocompleteOnFocus: true
        autocomplete: {
          source: source
          response: (e, ui) ->
            return if !ui
            return if !ui.content
            for item in ui.content
              possibleTags[item.value] = true
        },
      ).on('tokenfield:createtoken', (e) ->
        if App.Config.get('tag_new') is false && !possibleTags[e.attrs.value]
          e.preventDefault()
          return false
        true
      )

      # If field was already focused, add what was alredy typed into the new tokenfield and focus it (#5838)
      if isFocused
        $(fieldName + '-tokenfield' )
          .val(addedValue)
          .focus()

      $('#' + attribute.id ).parent().css('height', 'auto')
    App.Delay.set(a, 500, undefined, 'tags')
    item

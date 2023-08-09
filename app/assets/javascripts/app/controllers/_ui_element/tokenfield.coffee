# coffeelint: disable=camel_case_classes
class App.UiElement.tokenfield
  @valueType: 'json'

  @render: (attributeConfig) ->
    attribute = $.extend(true, {}, attributeConfig)

    if !attribute.id
      attribute.id = 'tokenfield-' + new Date().getTime() + '-' + Math.floor(Math.random() * 999999)

    item = $( App.view('generic/input')(attribute: attribute) )
      .attr('data-value-type', @valueType)
      .data('value-type', @valueType)

    if not _.isNull(attribute.value) or not _.isUndefined(attribute.value)

      # Compatibility layer for renamed operators (#4709).
      if not _.isArray(attribute.value)
        attribute.value = [attribute.value]

      value = @setValue(item, attribute.value)

    callback = =>
      item.tokenfield(
        beautify: false
        createTokensOnBlur: true
        delimiter: ''
        tokens: value or []
      )
        .on('tokenfield:createdtoken', => @updateValue(item))
        .on('tokenfield:editedtoken', => @updateValue(item))
        .on('tokenfield:removedtoken', => @updateValue(item))

      item.parent().css('height', 'auto')

    App.Delay.set(callback, 500, undefined, 'token')

    item

  @updateValue: (item) =>
    tokens = item.tokenfield('getTokens')
    @setValue(item, tokens.map((token) -> token.value))

    true

  @setValue: (item, newValue) ->
    jsonValue = JSON.stringify(newValue)
    item.attr('data-value', jsonValue)
      .data('value', jsonValue)

    newValue

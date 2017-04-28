# coffeelint: disable=camel_case_classes
class App.UiElement.tag
  @render: (attribute) ->
    if !attribute.id
      attribute.id = 'tag-' + new Date().getTime() + '-' + Math.floor(Math.random() * 999999)
    item = $( App.view('generic/input')(attribute: attribute) )
    source = "#{App.Config.get('api_path')}/tag_search"
    possibleTags = {}
    a = ->
      $('#' + attribute.id ).tokenfield(
        createTokensOnBlur: true
        autocomplete: {
          source: source
          minLength: 2
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
      $('#' + attribute.id ).parent().css('height', 'auto')
    App.Delay.set(a, 500, undefined, 'tags')
    item

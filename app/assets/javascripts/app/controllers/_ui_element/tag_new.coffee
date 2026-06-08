# coffeelint: disable=camel_case_classes
class App.UiElement.tag_new
  @render: (attributeConfig) ->
    attribute = $.extend(true, {}, attributeConfig)

    if !attribute.id
      attribute.id = 'tag-' + new Date().getTime() + '-' + Math.floor(Math.random() * 999999)
    item = $( App.view('generic/input')(attribute: attribute) )
    a = ->
      $('#' + attribute.id ).tokenfield(
        createTokensOnBlur: true
      )
      $('#' + attribute.id ).parent().css('height', 'auto')
    App.Delay.set(a, 500, undefined, 'tags')
    item

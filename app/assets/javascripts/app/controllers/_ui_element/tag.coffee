# coffeelint: disable=camel_case_classes
class App.UiElement.tag
  @render: (attribute) ->
    item = $( App.view('generic/input')( attribute: attribute ) )
    a = ->
      $('#' + attribute.id ).tokenfield(createTokensOnBlur: true)
      $('#' + attribute.id ).parent().css('height', 'auto')
    App.Delay.set(a, 120, undefined, 'tags')
    item
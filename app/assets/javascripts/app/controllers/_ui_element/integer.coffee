# coffeelint: disable=camel_case_classes
class App.UiElement.integer
  @render: (attribute) ->
    attribute.type = 'number'
    attribute.step = '1'
    $( App.view('generic/input')( attribute: attribute ) )

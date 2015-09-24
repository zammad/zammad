# coffeelint: disable=camel_case_classes
class App.UiElement.input
  @render: (attribute) ->
    $( App.view('generic/input')( attribute: attribute ) )

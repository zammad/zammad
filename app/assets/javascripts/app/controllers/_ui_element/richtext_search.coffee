# coffeelint: disable=camel_case_classes
class App.UiElement.richtext_search
  @render: (attribute) ->
    $( App.view('generic/input')( attribute: attribute ) )

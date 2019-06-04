# coffeelint: disable=camel_case_classes
class App.UiElement.color extends App.UiElement.ApplicationUiElement
  @render: (attribute, params) ->
    new App.Color(attribute: attribute).element()

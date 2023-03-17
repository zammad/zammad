# coffeelint: disable=camel_case_classes
class App.UiElement.icon_picker extends App.UiElement.ApplicationUiElement
  @render: (attribute, params) ->
    new App.IconPicker(attribute: attribute).element()

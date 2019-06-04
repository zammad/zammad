# coffeelint: disable=camel_case_classes
class App.UiElement.iconset_picker extends App.UiElement.ApplicationUiElement
  @render: (attribute, params) ->
    new App.IconsetPicker(attribute: attribute).element()

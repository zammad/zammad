# coffeelint: disable=camel_case_classes
class App.UiElement.code_editor
  @render: (attribute) ->
    new App.CodeEditor(attribute: attribute).element()

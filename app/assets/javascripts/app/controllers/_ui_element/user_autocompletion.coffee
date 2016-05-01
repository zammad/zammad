# coffeelint: disable=camel_case_classes
class App.UiElement.user_autocompletion
  @render: (attribute, params = {}) ->
    new App.UserOrganizationAutocompletion(attribute: attribute, params: params).element()

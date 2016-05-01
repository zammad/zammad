# coffeelint: disable=camel_case_classes
class App.UiElement.user_autocompletion_search
  @render: (attributeOrig, params = {}) ->
    attribute = _.clone(attributeOrig)
    attribute.disableCreateUser = true
    new App.UserOrganizationAutocompletion(attribute: attribute, params: params).element()

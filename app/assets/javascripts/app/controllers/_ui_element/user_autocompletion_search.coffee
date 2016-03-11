# coffeelint: disable=camel_case_classes
class App.UiElement.user_autocompletion_search
  @render: (attributeOrig) ->
    attribute = _.clone(attributeOrig)
    attribute.disableCreateUser = true
    new App.UserOrganizationAutocompletion(attribute: attribute).element()

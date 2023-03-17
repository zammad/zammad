# coffeelint: disable=camel_case_classes
class App.UiElement.user_autocompletion_search
  @render: (attributeConfig, params) ->
    attribute = $.extend(true, {}, attributeConfig)
    attribute.disableCreateObject = true
    attribute.multiple = true
    new App.UserOrganizationAutocompletion(attribute: attribute, params: params).element()

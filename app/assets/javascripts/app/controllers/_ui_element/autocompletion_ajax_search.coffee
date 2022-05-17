# coffeelint: disable=camel_case_classes
class App.UiElement.autocompletion_ajax_search extends App.UiElement.autocompletion_ajax
  @render: (attributeConfig, params = {}, form) ->
    attribute = $.extend(true, {}, attributeConfig)

    attribute.multiple = true
    super(attribute, params = {}, form)

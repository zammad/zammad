# coffeelint: disable=camel_case_classes
class App.UiElement.autocompletion_ajax_search extends App.UiElement.autocompletion_ajax
  @render: (attributeOrig, params = {}, form) ->
    attribute = _.clone(attributeOrig)
    attribute.multiple = true
    super(attribute, params = {}, form)

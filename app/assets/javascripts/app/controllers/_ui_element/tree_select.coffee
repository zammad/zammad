# coffeelint: disable=camel_case_classes
class App.UiElement.tree_select extends App.UiElement.ApplicationTreeSelect
  @render: (attributeConfig, params) ->
    attribute = $.extend({}, attributeConfig)

    # set multiple option
    if attribute.multiple
      attribute.multiple = 'multiple'
    else
      attribute.multiple = ''

    super

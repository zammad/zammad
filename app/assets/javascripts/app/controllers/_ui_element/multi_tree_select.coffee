# coffeelint: disable=camel_case_classes
class App.UiElement.multi_tree_select extends App.UiElement.ApplicationTreeSelect
  @render: (attributeConfig, params) ->
    attribute = $.extend(true, {}, attributeConfig)

    # set multiple option
    attribute.multiple = 'multiple'

    super

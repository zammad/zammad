# coffeelint: disable=camel_case_classes
class App.UiElement.tree_select_search extends App.UiElement.multi_tree_select
  @render: (attributeConfig, params) ->
    attributeConfig = $.extend(true, {}, attributeConfig)

    attributeConfig.multiple   = true
    attributeConfig.nulloption = true

    super

# coffeelint: disable=camel_case_classes
class App.UiElement.datetime_search
  @render: (attributeConfig) ->
    attribute = $.extend(true, {}, attributeConfig)

    attribute.disable_feature = true
    attribute.null = false
    App.UiElement.datetime.render(attribute)

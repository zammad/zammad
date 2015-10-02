# coffeelint: disable=camel_case_classes
class App.UiElement.datetime_search
  @render: (attributeOrig) ->
    attribute = _.clone(attributeOrig)
    attribute.disable_feature = true
    attribute.null = false
    App.UiElement.datetime.render(attribute)

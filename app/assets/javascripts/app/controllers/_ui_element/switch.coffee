# coffeelint: disable=camel_case_classes
class App.UiElement.switch
  @render: (attributeConfig) ->
    item = $( App.view('generic/switch')( attribute: attributeConfig ) )
    item.find('input').data('field-type', 'boolean')
    item

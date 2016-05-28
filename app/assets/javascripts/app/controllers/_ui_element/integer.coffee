# coffeelint: disable=camel_case_classes
class App.UiElement.integer
  @render: (attribute) ->
    attribute.type = 'number'
    attribute.step = '1'
    item = $( App.view('generic/input')(attribute: attribute) )
    item.data('field-type', 'integer')
    item
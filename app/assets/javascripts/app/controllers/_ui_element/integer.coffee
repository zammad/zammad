# coffeelint: disable=camel_case_classes
class App.UiElement.integer
  @render: (attribute) ->
    attribute.type = 'number'
    attribute.step = '1'
    item = $( App.view('generic/input')(attribute: attribute) )
    item.find('select').data('field-type', 'integer')
    item
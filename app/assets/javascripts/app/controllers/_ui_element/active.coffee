# coffeelint: disable=camel_case_classes
class App.UiElement.active extends App.UiElement.ApplicationUiElement
  @render: (attribute, params) ->

    # set attributes
    attribute.null = false
    attribute.translation = true

    # build options list
    attribute.options = [
      { name: 'active', value: true }
      { name: 'inactive', value: false }
    ]

    # set data type
    if attribute.name
      attribute.name = '{boolean}' + attribute.name

    # build options list based on config
    @getConfigOptionList(attribute, params)

    # sort attribute.options
    @sortOptions(attribute, params)

    # finde selected/checked item of list
    @selectedOptions(attribute, params)

    # return item
    $( App.view('generic/select')( attribute: attribute ) )
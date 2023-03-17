# coffeelint: disable=camel_case_classes
class App.UiElement.active extends App.UiElement.ApplicationUiElement
  @render: (attributeConfig, params) ->
    attribute = $.extend(true, {}, attributeConfig)

    # set attributes
    attribute.null = false
    attribute.translate = true

    # build options list
    attribute.options = [
      { name: __('active'), value: true }
      { name: __('inactive'), value: false }
    ]

    # build options list based on config
    @getConfigOptionList(attribute, params)

    # sort attribute.options
    @sortOptions(attribute, params)

    # find selected/checked item of list
    @selectedOptions(attribute, params)

    # return item
    item = $( App.view('generic/select')(attribute: attribute) )
    item.find('select').data('field-type', 'boolean')
    item
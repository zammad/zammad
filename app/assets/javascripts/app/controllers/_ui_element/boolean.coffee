# coffeelint: disable=camel_case_classes
class App.UiElement.boolean extends App.UiElement.ApplicationUiElement
  @render: (attributeConfig, params) ->
    attribute = $.extend(true, {}, attributeConfig)

    # build options list
    if _.isEmpty(attribute.options)
      attribute.options = [
        { name: __('yes'), value: true }
        { name: __('no'), value: false }
      ]
      attribute.translate = true

    # build options list based on config
    @getConfigOptionList(attribute, params)

    # sort attribute.options
    @sortOptions(attribute, params)

    # find selected/checked item of list
    @selectedOptions(attribute, params)

    # disable item of list
    @disabledOptions(attribute, params)

    # filter attributes
    @filterOption(attribute, params)

    item = $(App.view('generic/select')(attribute: attribute))
    item.find('select').data('field-type', 'boolean')
    item

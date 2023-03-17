# coffeelint: disable=camel_case_classes
class App.UiElement.ApplicationTreeSelect extends App.UiElement.ApplicationUiElement
  @optionsSelect: (children, value) ->
    return if !children
    for child in children
      if child.value is value
        child.selected = true
      if child.children
        @optionsSelect(child.children, value)

  @filterTreeOptions: (values, valueDepth, options, nullExists) ->
    newOptions = []
    nullFound = false
    for option, index in options
      enabled = false
      for value in values
        valueArray  = value.split('::')
        optionArray = option['value'].split('::')
        continue if valueArray[valueDepth] isnt optionArray[valueDepth]
        enabled = true
        break

      if nullExists && !option.value && !nullFound
        nullFound = true
        enabled   = true

      if !enabled
        continue

      if option['children'] && option['children'].length
        option['children'] = @filterTreeOptions(values, valueDepth + 1, option['children'], nullExists)

      newOptions.push(option)

    return newOptions

  @filterOptionArray: (attribute) ->
    attribute.options = @filterTreeOptions(attribute.filter, 0, attribute.options, attribute.null)

  @render: (attributeConfig, params) ->
    attribute = $.extend(true, {}, attributeConfig)

    # set multiple option
    if attribute.multiple
      attribute.multiple = 'multiple'
    else
      attribute.multiple = ''

    # add deleted historical options if required
    @addDeletedOptions(attribute, params)

    # build options list based on config
    @getConfigOptionList(attribute, params)

    # build options list based on relation
    @getRelationOptionList(attribute, params)

    # add null selection if needed
    @addNullOption(attribute, params)

    # sort attribute.options
    @sortOptions(attribute, params)

    # find selected/checked item of list
    if attribute.options
      @optionsSelect(attribute.options, attribute.value)

    # disable item of list
    @disabledOptions(attribute, params)

    # filter attributes
    @filterOption(attribute, params)

    new App.SearchableSelect(attribute: attribute).element()

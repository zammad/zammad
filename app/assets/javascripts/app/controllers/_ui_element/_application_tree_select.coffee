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
      enabled = _.contains(values, option.value)
      if nullExists && !option.value && !nullFound
        nullFound = true
        enabled   = true

      activeChildren = false
      if option.value && option.children && option.children.length > 0
        for value in values
          if value && value.startsWith(option.value + '::')
            activeChildren = true

      if activeChildren
        option.inactive = !enabled
        option.children = @filterTreeOptions(values, valueDepth + 1, option.children, nullExists)
      else
        option.children = undefined
        continue if !enabled

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

    # make sure only available values are set. For the tree selects
    # we want also to render values which are not selectable but rendered as disabled
    # e.g. child nodes where the parent node is disabled. Because of this we need
    # to make sure to not render these values as selected
    if attribute.value && attribute.filter
      if attribute.multiple
        attribute.value = _.intersection(attribute.value, attribute.filter)
      else if !_.contains(attribute.filter, attribute.value)
        attribute.value = ''

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

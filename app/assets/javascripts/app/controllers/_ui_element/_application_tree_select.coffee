# coffeelint: disable=camel_case_classes
class App.UiElement.ApplicationTreeSelect extends App.UiElement.ApplicationUiElement
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

  @optionsSelect: (children, value) ->
    return if !children
    for child in children
      if child.value?.toString() is value?.toString()
        child.selected = true
      if child.children
        @optionsSelect(child.children, value)

  @filterTreeOptions: (attribute, valueDepth, options) ->
    newOptions = []
    nullFound = false
    for option, index in options
      enabled = _.contains(attribute.filter, option.value.toString())
      if attribute.null && !option.value && !nullFound
        nullFound = true
        enabled   = true

      activeChildren = false
      if option.value && option.children && option.children.length > 0
        if @isTreeRelation(attribute)
          all_children_ids = _.map(App[attribute.relation].find(option.value).all_children(), (group) -> group.id.toString())
          if _.intersection(attribute.filter, all_children_ids).length > 0
            activeChildren = true
        else
          for value in attribute.filter
            if value && value.startsWith(option.value + '::')
              activeChildren = true

      if activeChildren
        option.inactive = !enabled
        option.children = @filterTreeOptions(attribute, valueDepth + 1, option.children)
      else
        option.children = undefined
        continue if !enabled

      newOptions.push(option)

    return newOptions

  @filterOptionArray: (attribute) ->
    attribute.options = @filterTreeOptions(attribute, 0, attribute.options)

  @buildOptionList: (list, attribute) ->
    return super if !@isTreeRelation(attribute)

    parents           = list.filter((obj) -> !obj.parent_id)
    attribute.options = @buildOptionListTreeRelation(list, attribute, parents)
    attribute.sortBy  = null

  @buildOptionListTreeRelation: (list, attribute, entries) ->
    result = []
    for item in entries
      row = @buildOptionListRow(attribute, item)
      continue if !row

      children = _.filter(list, (obj) -> obj.parent_id is item.id)
      children = @buildOptionListTreeRelation(list, attribute, children)
      if children.length > 0
        row.children = children

      result.push row
    result

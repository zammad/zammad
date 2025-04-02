class App.UiElement.ApplicationUiElement

  # sort attribute.options
  @sortOptions: (attribute) ->

    # skip sorting if it is disabled by config
    return if attribute.sortBy == null

    return if _.isEmpty(attribute.options)

    # arrays can only get ordered
    if _.isArray(attribute.options)

      # reverse - we have to exit early
      if attribute.order && attribute.order == 'DESC'
        attribute.options = attribute.options.reverse()
      return

    # sort by name
    optionsByName = []
    optionsByNameWithValue = {}
    for i, value of attribute.options
      valueTmp = value.toString().toLowerCase()
      optionsByName.push valueTmp
      optionsByNameWithValue[valueTmp] = i
    optionsByName = optionsByName.sort()

    # do a reverse, if needed
    if attribute.order && attribute.order == 'DESC'
      optionsByName = optionsByName.reverse()

    optionsNew = []
    for i in optionsByName
      optionsNew.push optionsByNameWithValue[i]
    attribute.options = optionsNew

  @addNullOption: (attribute) ->
    return if !attribute.options
    return if !attribute.nulloption
    if _.isArray(attribute.options)
      attribute.options.unshift({ name: '-', value: '' })
    else
      attribute.options[''] = '-'

  @getConfigOptionListArray: (attribute, selection) ->
    result = []
    for row in selection
      if attribute.translate
        row.name = App.i18n.translatePlain(row.name)
        if !_.isEmpty(row.children)
          row.children = @getConfigOptionListArray(attribute, row.children)
      result.push row
    result

  @getConfigOptionList: (attribute, children = false) ->
    return if _.isEmpty(attribute.options)
    selection = attribute.options
    attribute.options = []
    if _.isArray(selection)
      attribute.options = @getConfigOptionListArray(attribute, selection)
    else
      forceString = (s) ->
        return if !selection[s] || !selection[s].toString then '' else selection[s].toString()
      order = _.keys(selection).sort( (a, b) -> forceString(a).localeCompare(forceString(b)) )
      for key in order
        name_new = selection[key]
        if attribute.translate
          name_new = App.i18n.translatePlain(name_new)
        attribute.options.push {
          name:  name_new
          value: key
        }
    attribute.sortBy = null

  @getConfigCustomSortOptionList: (attribute) ->
    if attribute.customsort && attribute.customsort is 'on'
      if !_.isEmpty(attribute.options)
        selection = attribute.options
        attribute.options = []
        if _.isArray(selection)
          attribute.options = @getConfigOptionListArray(attribute, selection)
        else
          keys = _.keys(selection)
          for key in keys
            name_new = selection[key]
            if attribute.translate
              name_new = App.i18n.translatePlain(name_new)
            attribute.options.push {
              name:  name_new
              value: key
            }
        attribute.sortBy = null
    else
      @getConfigOptionList(attribute)

  @getRelationOptionListSearchParams: (attribute) ->
    result =
      sortBy: attribute.sortBy
    if attribute.filter && _.isArray(attribute.filter) && attribute.tag is 'select'
      result.translate = attribute.translate
    result

  @getRelationOptionList: (attribute, params) ->

    # build options list based on relation
    return if _.isEmpty(attribute.relation)
    return if !App[attribute.relation]

    attribute.options = []
    list              = []
    searchParams      = @getRelationOptionListSearchParams(attribute)
    if attribute.filter

      App.Log.debug 'ControllerForm', '_getRelationOptionList:filter', attribute.filter

      # function based filter
      if typeof attribute.filter is 'function'
        App.Log.debug 'ControllerForm', '_getRelationOptionList:filter-function'

        all = App[ attribute.relation ].search(searchParams)

        list = attribute.filter(all, 'collection', params)

      # data based filter
      else if attribute.filter[ attribute.name ]
        filter = attribute.filter[ attribute.name ]

        App.Log.debug 'ControllerForm', '_getRelationOptionList:filter-data', filter

        # check all records
        for record in App[ attribute.relation ].search(searchParams)

          # check all filter attributes
          for key in filter

            # check all filter values as array
            # if it's matching, use it for selection
            if record['id'] is key
              list.push record

      # data based filter
      else if attribute.filter && _.isArray(attribute.filter) && attribute.tag is 'select'
        App.Log.debug 'ControllerForm', '_getRelationOptionList:filter-array', attribute.filter

        filter = _.clone(attribute.filter)
        if !attribute.rejectNonExistentValues && params[ attribute.name ] && !_.contains(filter, params[ attribute.name ])
          filter.push(params[ attribute.name ])

        # check all records
        for record in App[ attribute.relation ].search(searchParams)

          # check all filter attributes
          for key in filter

            # check all filter values as array
            # if it's matching, use it for selection
            if record['id'] is key || ( record['id'] && key && record['id'].toString() is key.toString() )
              list.push record

      # no data filter matched
      else
        App.Log.debug 'ControllerForm', '_getRelationOptionList:filter-data no filter matched'
        list = App[ attribute.relation ].search(searchParams)
    else
      App.Log.debug 'ControllerForm', '_getRelationOptionList:filter-no filter defined'
      list = App[ attribute.relation ].search(searchParams)

    # Turn on attribute translation if configured for the relation object.
    if 'configure_translate' in App[attribute.relation]
      attribute.translate = App[attribute.relation].configure_translate

    App.Log.debug 'ControllerForm', '_getRelationOptionList', attribute, list

    if @isTreeRelation(attribute)
      @setTreeRelationData(list, attribute)

    # build options list
    @buildOptionList(list, attribute)

  @hasActiveChildren: (attribute, children, filter = undefined) ->
    return false if !children

    for row in children
      return true if row.active && (!filter || _.contains(filter, row.id.toString()))

      childrenActive = @hasActiveChildren(attribute, attribute.tree_children[row.id.toString()], filter)
      return true if childrenActive

    return false

  @buildOptionListRow: (attribute, item) ->

    # check if element is selected, show it anyway - ignore active state
    activeSupport = ('active' of item)
    isSelected = false
    if activeSupport && !item.active
      isSelected = @_selectedOptionsIsSelected(attribute.value, {name: item.name || '', value: item.id})

    hasActiveChildren = false
    if @isTreeRelation(attribute)
      hasActiveChildren = @hasActiveChildren(attribute, attribute.tree_children[item.id.toString()])

    # if active or if active doesn't exist
    return if !item.active && activeSupport && !isSelected && !hasActiveChildren

    nameNew = '?'
    if @isTreeRelation(attribute)
      nameNew = item.name_last || item.name
      if attribute.display_full_name
        nameNew = item.displayName()
    else if item.displayName
      nameNew = item.displayName()
    else if item.name
      nameNew = item.name

    if attribute.translate
      nameNew = App.i18n.translatePlain(nameNew)

    row =
      value: item.id,
      note:  item.note,
      name:  nameNew,
      title: if item.email then item.email else nameNew

    if item.graphic
      row.graphic = item.graphic

      # only used for graphics
      if item.aspect_ratio
        row.aspect_ratio = item.aspect_ratio

    row

  # build options list
  @buildOptionList: (list, attribute) ->
    for item in list
      row = @buildOptionListRow(attribute, item)
      continue if !row
      attribute.options.push row

    attribute.sortBy = null

  # execute filter
  @filterOption: (attribute) ->
    return if !attribute.filter
    return if _.isEmpty(attribute.options)

    if typeof attribute.filter is 'function'
      App.Log.debug 'ControllerForm', '_filterOption:filter-function'
      attribute.options = attribute.filter(attribute.options, attribute)
    else if (@isTreeRelation(attribute) || !attribute.relation) && attribute.filter && _.isArray(attribute.filter)
      @filterOptionArray(attribute)

    # make sure only available values are set. For the tree selects
    # we want also to render values which are not selectable but rendered as disabled
    # e.g. child nodes where the parent node is disabled. Because of this we need
    # to make sure to not render these values as selected
    values = @optionSelectableValues(attribute.options)
    if attribute.multiple
      attribute.value = _.intersection(attribute.value, values)
    else if !_.contains(values, attribute.value)
      attribute.value = ''

  @optionSelectableValues: (values) ->
    result = []
    for option in values
      continue if option.inactive
      continue if !_.isEmpty(option.disabled)

      result.push(option.value.toString())
      result = result.concat(@optionSelectableValues(option.children)) if _.isArray(option.children)
    result

  @filterOptionArray: (attribute) ->
    result = []
    for option in attribute.options
      for value in attribute.filter
        if value.toString() == option.value.toString()
          result.push(option)

    attribute.options = result

  # set selected attributes
  @selectedOptions: (attribute, params) ->
    return if !attribute.options

    # lookup of any record, if it needs to be selected
    for record in attribute.options
      if @_selectedOptionsIsSelected(attribute.value, record)
        record.selected = 'selected'
        record.checked = 'checked'

    return if params?.id

    # if nothing is selected / checked, use default as selected / checked
    selected = false
    for record in attribute.options
      if record.selected || record.checked
        selected = true
    if !selected
      for record in attribute.options
        if @_selectedOptionsIsSelected(attribute.default, record)
          record.selected = 'selected'
          record.checked = 'checked'

  @_selectedOptionsIsSelected: (value, record) ->
    if _.isArray(value)
      for valueItem in value
        if @_selectedOptionsIsSelectedItem(valueItem, record)
          return true
    if value is null || value is undefined || typeof value is 'string' || typeof value is 'number' || typeof value is 'boolean'
      if @_selectedOptionsIsSelectedItem(value, record)
        return true
    false

  @_selectedOptionsIsSelectedItem: (valueOrigin, record) ->
    # if name or value is matching
    value = valueOrigin
    if value is null || value is undefined
      value = ''
    recordValue = record.value
    if recordValue is null || recordValue is undefined
      recordValue = ''
    recordName = record.name
    if recordName is null || recordName is undefined
      recordName = ''
    if typeof value is 'string' || typeof value is 'number' || typeof value is 'boolean'
      if recordValue.toString() is value.toString() || recordName.toString() is value.toString()
        return true
    else if ( value && recordValue && _.include(value, recordValue) ) || ( value && recordName && _.include(value, recordName) )
      return true
    false

  # set disabled attributes
  @disabledOptions: (attribute) ->

    return if !attribute.options
    return if !_.isArray(attribute.options)

    for record in attribute.options
      if record.disable is true
        record.disabled = 'disabled'
      else
        record.disabled = ''

  @findOption: (options, value) ->
    return if !_.isArray(options)
    for option in options
      return option if option.value is value
      if option.children
        result = @findOption(option.children, value)
        return result if result

  # 1. If attribute.value is not among the current options, then search within historical options
  # 2. If attribute.value is not among current and historical options, then add the value itself as an option
  @addDeletedOptions: (attribute) ->
    return if !_.isEmpty(attribute.relation) # do not apply for attributes with relation, relations will fill options automatically
    return if attribute.rejectNonExistentValues
    value = attribute.value
    return if !value
    return if !attribute.options

    values = value
    if !_.isArray(value)
      values = [value]

    attribute.historical_options ||= {}
    if _.isArray(attribute.options)
      for value in values
        continue if !value
        continue if @findOption(attribute.options, value)
        attribute.options.push(
          value: value
          name: attribute.historical_options[value] || value
        )
    else
      for value in values
        continue if !value
        continue if attribute.options[value]
        attribute.options[value] = attribute.historical_options[value] || value

  @isTreeRelation: (attribute) ->
    return false if !attribute.relation
    return false if !_.find(App[attribute.relation].configure_attributes, (attr) -> attr.name is 'parent_id')
    return true

  @setTreeRelationData: (list, attribute) ->
    tree_children = {}
    for row in list
      parent_id = row.parent_id?.toString() || '-NONE-'
      tree_children[parent_id] ||= []
      tree_children[parent_id].push(row)

    attribute.tree_children = tree_children

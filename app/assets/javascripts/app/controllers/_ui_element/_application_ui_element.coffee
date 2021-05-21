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
        row.name = App.i18n.translateInline(row.name)
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
          name_new = App.i18n.translateInline(name_new)
        attribute.options.push {
          name:  name_new
          value: key
        }
    attribute.sortBy = null

  @getRelationOptionList: (attribute, params) ->

    # build options list based on relation
    return if _.isEmpty(attribute.relation)
    return if !App[attribute.relation]

    attribute.options = []
    list              = []
    if attribute.filter

      App.Log.debug 'ControllerForm', '_getRelationOptionList:filter', attribute.filter

      # function based filter
      if typeof attribute.filter is 'function'
        App.Log.debug 'ControllerForm', '_getRelationOptionList:filter-function'

        all = App[ attribute.relation ].search(sortBy: attribute.sortBy)

        list = attribute.filter(all, 'collection', params)

      # data based filter
      else if attribute.filter[ attribute.name ]
        filter = attribute.filter[ attribute.name ]

        App.Log.debug 'ControllerForm', '_getRelationOptionList:filter-data', filter

        # check all records
        for record in App[ attribute.relation ].search(sortBy: attribute.sortBy)

          # check all filter attributes
          for key in filter

            # check all filter values as array
            # if it's matching, use it for selection
            if record['id'] is key
              list.push record

      # data based filter
      else if attribute.filter && _.isArray attribute.filter

        App.Log.debug 'ControllerForm', '_getRelationOptionList:filter-array', attribute.filter

        # check all records
        for record in App[ attribute.relation ].search(sortBy: attribute.sortBy, translate: attribute.translate)

          # check all filter attributes
          for key in attribute.filter

            # check all filter values as array
            # if it's matching, use it for selection
            if record['id'] is key || ( record['id'] && key && record['id'].toString() is key.toString() )
              list.push record

        # check if current value need to be added
        if params[ attribute.name ] && !attribute.rejectNonExistentValues
          hit = false
          for value in list
            if value['id'].toString() is params[ attribute.name ].toString()
              hit = true
          if !hit
            currentRecord = App[ attribute.relation ].find(params[ attribute.name ])
            list.push currentRecord

      # no data filter matched
      else
        App.Log.debug 'ControllerForm', '_getRelationOptionList:filter-data no filter matched'
        list = App[ attribute.relation ].search(sortBy: attribute.sortBy)
    else
      App.Log.debug 'ControllerForm', '_getRelationOptionList:filter-no filter defined'
      list = App[ attribute.relation ].search(sortBy: attribute.sortBy)

    App.Log.debug 'ControllerForm', '_getRelationOptionList', attribute, list

    # build options list
    @buildOptionList(list, attribute)

  # build options list
  @buildOptionList: (list, attribute) ->

    for item in list

      # check if element is selected, show it anyway - ignore active state
      activeSupport = ('active' of item)
      isSelected = false
      if activeSupport && !item.active
        isSelected = @_selectedOptionsIsSelected(attribute.value, {name: item.name || '', value: item.id})

      # if active or if active doesn't exist
      if item.active || !activeSupport || isSelected
        nameNew = '?'
        if item.displayName
          nameNew = item.displayName()
        else if item.name
          nameNew = item.name

        if attribute.translate
          nameNew = App.i18n.translateInline(nameNew)

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

        attribute.options.push row

    attribute.sortBy = null

  # execute filter
  @filterOption: (attribute) ->
    return if !attribute.filter
    return if _.isEmpty(attribute.options)

    return if typeof attribute.filter isnt 'function'
    App.Log.debug 'ControllerForm', '_filterOption:filter-function'

    attribute.options = attribute.filter(attribute.options, attribute)

  # set selected attributes
  @selectedOptions: (attribute) ->
    return if !attribute.options

    # lookup of any record, if it needs to be selected
    for record in attribute.options
      if @_selectedOptionsIsSelected(attribute.value, record)
        record.selected = 'selected'
        record.checked = 'checked'

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

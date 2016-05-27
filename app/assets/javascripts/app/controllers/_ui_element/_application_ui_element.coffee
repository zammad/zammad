class App.UiElement.ApplicationUiElement

  # sort attribute.options
  @sortOptions: (attribute) ->

    # skip sorting if it is disabled by config
    return if attribute.sortBy == null

    return if !attribute.options

    if _.isArray(attribute.options)
      # reverse if we have to exit early, if configured
      if attribute.order
        if attribute.order == 'DESC'
          attribute.options = attribute.options.reverse()
        return

    options_by_name = []
    for i in attribute.options
      options_by_name.push i['name'].toString().toLowerCase()
    options_by_name = options_by_name.sort()

    options_new = []
    options_new_used = {}
    for i in options_by_name
      for ii, vv in attribute.options
        if !options_new_used[ ii['value'] ] && i.toString().toLowerCase() is ii['name'].toString().toLowerCase()
          options_new_used[ ii['value'] ] = 1
          options_new.push ii
    attribute.options = options_new

    # do a final reverse, if configured
    if attribute.order
      if attribute.order == 'DESC'
        attribute.options = attribute.options.reverse()

  @addNullOption: (attribute) ->
    return if !attribute.options
    return if !attribute.nulloption
    if _.isArray( attribute.options )
      attribute.options.unshift({ name: '-', value: '' })
    else
      attribute.options[''] = '-'

  @getConfigOptionList: (attribute) ->
    return if !attribute.options
    selection = attribute.options
    attribute.options = []
    if _.isArray(selection)
      for row in selection
        if attribute.translate
          row.name = App.i18n.translateInline(row.name)
        attribute.options.push row
    else
      order = _.sortBy(
        _.keys(selection), (item) ->
          selection[item].toString().toLowerCase()
      )
      for key in order
        name_new = selection[key]
        if attribute.translate
          name_new = App.i18n.translateInline(name_new)
        attribute.options.push {
          name:  name_new
          value: key
        }

  @getRelationOptionList: (attribute, params) ->

    # build options list based on relation
    return if !attribute.relation
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
        for record in App[ attribute.relation ].search(sortBy: attribute.sortBy)

          # check all filter attributes
          for key in attribute.filter

            # check all filter values as array
            # if it's matching, use it for selection
            if record['id'] is key || ( record['id'] && key && record['id'].toString() is key.toString() )
              list.push record

        # check if current value need to be added
        if params[ attribute.name ]
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
        name_new = '?'
        if item.displayName
          name_new = item.displayName()
        else if item.name
          name_new = item.name
        if attribute.translate
          name_new = App.i18n.translateInline(name_new)
        attribute.options.push {
          name:  name_new,
          value: item.id,
          note:  item.note,
        }

  # execute filter
  @filterOption: (attribute) ->
    return if !attribute.filter
    return if !attribute.options

    return if typeof attribute.filter isnt 'function'
    App.Log.debug 'ControllerForm', '_filterOption:filter-function'

    attribute.options = attribute.filter(attribute.options, attribute)

  # set selected attributes
  @selectedOptions: (attribute) ->
    return if !attribute.options

    # lookup of any record, if it need to be selected
    for record in attribute.options
      if @_selectedOptionsIsSelected(attribute.value, record)
        record.selected = 'selected'
        record.checked = 'checked'

    # if noting is selected / checked, use default as selected / checked
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
    if typeof value is 'string' || typeof value is 'number' || typeof value is 'boolean'
      if @_selectedOptionsIsSelectedItem(value, record)
        return true
    false

  @_selectedOptionsIsSelectedItem: (value, record) ->
    # if name or value is matching
    if typeof value is 'string' || typeof value is 'number' || typeof value is 'boolean'
      if record.value.toString() is value.toString() || record.name.toString() is value.toString()
        return true
    else if ( value && record.value && _.include(value, record.value) ) || ( value && record.name && _.include(value, record.name) )
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

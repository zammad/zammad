class App.ControllerTable extends App.Controller
  constructor: (params) ->
    for key, value of params
      @[key] = value

    @table = @tableGen(params)

    if @el
      @el.append( @table )

  ###

    # table based on model

    rowClick = (id, e) ->
      e.preventDefault()
      console.log('rowClick', id)
    rowMouseover = (id, e) ->
      e.preventDefault()
      console.log('rowMouseover', id)
    rowMouseout = (id, e) ->
      e.preventDefault()
      console.log('rowMouseout', id)
    rowDblClick = (id, e) ->
      e.preventDefault()
      console.log('rowDblClick', id)

    colClick = (id, e) ->
      e.preventDefault()
      console.log('colClick', e.target)

    checkboxClick = (id, e) ->
      e.preventDefault()
      console.log('checkboxClick', e.target)

    callbackHeader = (header) ->
      console.log('current header is', header)
      # add new header item
      attribute =
        name: 'some name'
        display: 'Some Name'
      header.push attribute
      console.log('new header is', header)

    callbackAttributes = (value, object, attribute, header, refObject) ->
      console.log('data of item col', value, object, attribute, header, refObject)
      value = 'New Data To Show'
      value

    new App.ControllerTable(
      el:       element
      overview: ['host', 'user', 'adapter', 'active']
      model:    App.Channel
      objects:  data
      groupBy:  'group'
      checkbox: false
      radio:    false
      class:    'some-css-class'
      bindRow:
        events:
          'click':      rowClick
          'mouseover':  rowMouseover
          'mouseout':   rowMouseout
          'dblclick':   rowDblClick
      bindCol:
        host:
          events:
            'click': colClick
      bindCheckbox:
        events:
          'click':      rowClick
          'mouseover':  rowMouseover
          'mouseout':   rowMouseout
          'dblclick':   rowDblClick
      callbackHeader:   callbackHeader
      callbackAttributes:
        attributeName: [
          callbackAttributes
        ]
    )

    new App.ControllerTable(
      el:       element
      overview: ['time', 'area', 'level', 'browser', 'location', 'data']
      attributes: [
        { name: 'time',     display: 'Time',      tag: 'datetime' },
        { name: 'area',     display: 'Area',      type: 'text' },
        { name: 'level',    display: 'Level',     type: 'text' },
        { name: 'browser',  display: 'Browser',   type: 'text' },
        { name: 'location', display: 'Location',  type: 'text' },
        { name: 'data',     display: 'Data',      type: 'text' },
      ]
      objects:  data
    )

  ###

  tableGen: (data) ->
    if !data.model
      data.model = {}
    overview   = data.overview || data.model.configure_overview || []
    attributes = data.attributes || data.model.configure_attributes || {}
    attributes = App.Model.attributesGet(false, attributes)
    destroy    = data.model.configure_delete

    # check if table is empty
    if _.isEmpty(data.objects)
      table = App.view('generic/admin/empty')
        explanation: data.explanation
      return $(table)

    # group by
    if data.groupBy

      # remove group by attribute from header
      overview = _.filter(
        overview
        (item) ->
          return item if item isnt data.groupBy
          return
      )

      # get new order
      groupObjects = _.groupBy(
        data.objects
        (item) ->
          return '' if !item[data.groupBy]
          return item[data.groupBy].displayName() if item[data.groupBy].displayName
          item[data.groupBy]
      )
      groupOrder = []
      for group, value of groupObjects
        groupOrder.push group

      # sort new groups
      groupOrder = _.sortBy(
        groupOrder
        (item) ->
          item
      )

      # create new data array
      data.objects = []
      for group in groupOrder
        data.objects = data.objects.concat groupObjects[group]
        groupObjects[group] = [] # release old array

    # get header data
    header = []
    for item in overview
      headerFound = false
      for attributeName, attribute of attributes
        if attributeName is item
          headerFound = true
          header.push attribute
        else
          rowWithoutId = item + '_id'
          if attributeName is rowWithoutId
            headerFound = true
            header.push attribute

    # execute header callback
    if data.callbackHeader
      header = data.callbackHeader(header)

    # get content
    @log 'debug', 'table', 'header', header, 'overview', 'objects', data.objects
    table = App.view('generic/table')(
      header:   header
      objects:  data.objects
      checkbox: data.checkbox
      radio:    data.radio
      groupBy:  data.groupBy
      class:    data.class
      destroy:  destroy
      callbacks: data.callbackAttributes
    )

    # convert to jquery object
    table = $(table)

    cursorMap =
      click:    'pointer'
      dblclick: 'pointer'
      #mouseover: 'alias'

    # bind col.
    if data.bindCol
      for name, item of data.bindCol
        if item.events
          position = 0
          if data.checkbox
            position += 1
          hit      = false

          for headerName in header
            if !hit
              position += 1
            if headerName.name is name || headerName.name is "#{name}_id"
              hit = true

          if hit
            for event, callback of item.events
              do (table, event, callback) ->
                if cursorMap[event]
                  table.find("tbody > tr > td:nth-child(#{position})").css( 'cursor', cursorMap[event] )
                table.on( event, "tbody > tr > td:nth-child(#{position})",
                  (e) ->
                    e.stopPropagation()
                    id = $(e.target).parents('tr').data('id')
                    callback(id, e)
                )

    # bind row
    if data.bindRow
      if data.bindRow.events
        for event, callback of data.bindRow.events
          do (table, event, callback) ->
            if cursorMap[event]
              table.find('tbody > tr').css( 'cursor', cursorMap[event] )
            table.on( event, 'tbody > tr',
              (e) ->
                id = $(e.target).parents('tr').data('id')
                callback(id, e)
            )

    # bind bindCheckbox
    if data.bindCheckbox
      if data.bindCheckbox.events
        for event, callback of data.bindCheckbox.events
          do (table, event, callback) ->
            table.delegate('input[name="bulk"]', event, (e) ->
              e.stopPropagation()
              id      = $(e.target).parents('tr').data('id')
              checked = $(e.target).prop('checked')
              callback(id, checked, e)
            )

    # bind on delete dialog
    if data.model && destroy
      table.delegate('[data-type="destroy"]', 'click', (e) =>
        e.stopPropagation()
        e.preventDefault()
        itemId = $(e.target).parents('tr').data('id')
        item   = data.model.find(itemId)
        new App.ControllerGenericDestroyConfirm(
          item:      item
          container: @container
        )
      )

    # enable checkbox bulk selection
    if data.checkbox

      # click first tr>td, catch click
      table.delegate('tr > td:nth-child(1)', event, (e) ->
        e.stopPropagation()
      )

      # bind on full bulk click
      table.delegate('input[name="bulk_all"]', 'click', (e) ->
        e.stopPropagation()
        if $(e.target).prop('checked')
          $(e.target).parents('table').find('[name="bulk"]').each( ->
            if !$(@).prop('checked')
              #$(@).prop('checked', true)
              $(@).trigger('click')
          )
        else
          $(e.target).parents('table').find('[name="bulk"]').each( ->
            if $(@).prop('checked')
              #$(@).prop('checked', false)
              $(@).trigger('click')
          )
      )

    table

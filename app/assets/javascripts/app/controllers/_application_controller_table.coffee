class App.ControllerTable extends App.Controller
  minColWidth: 40
  baseColWidth: 130
  minTableWidth: 612

  checkBoxColWidth: 40
  radioColWidth: 22

  elements:
    '.js-tableHead': 'tableHead'

  constructor: (params) ->
    for key, value of params
      @[key] = value

    # apply personal preferences
    data = @preferencesGet()
    if data['order']
      for key, value of data['order']
        @[key] = value

    @headerWidth = {}
    if data['headerWidth']
      for key, value of data['headerWidth']
        @headerWidth[key] = value

    @render()
    $(window).on 'resize.table', @onResize

  release: =>
    $(window).off 'resize.table', @onResize

  render: =>
    @html @tableGen()

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
      table_id: 'some_id_to_idientify_user_based_table_preferences'
      el:       element
      overview: ['host', 'user', 'adapter', 'active']
      model:    App.Channel
      objects:  data
      groupBy:  'adapter'
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
      callbackHeader:   [callbackHeader]
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

  tableGen: =>
    if !@model
      @model = {}
    overview   = @overview || @model.configure_overview || []
    attributes = @attributes || @model.configure_attributes || {}
    attributes = App.Model.attributesGet(false, attributes)
    destroy    = @model.configure_delete

    # check if table is empty
    if _.isEmpty(@objects)
      table = App.view('generic/admin/empty')
        explanation: @explanation
      return $(table)

    # get header data
    @headers = []
    for item in overview
      headerFound = false
      for attributeName, attribute of attributes

        # remove group by attribute from header
        if !@groupBy || @groupBy isnt item

          if !attribute.style
            attribute.style = {}

          if attributeName is item
            # e.g. column: owner
            headerFound = true
            if @headerWidth[attribute.name]
              attribute.width = "#{@headerWidth[attribute.name]}px"
            @headers.push attribute
          else
            # e.g. column: owner_id
            rowWithoutId = item + '_id'
            if attributeName is rowWithoutId
              headerFound = true
              if @headerWidth[attribute.name]
                attribute.width = "#{@headerWidth[attribute.name]}px"
              @headers.push attribute

    if @orderDirection && @orderBy
      for header in @headers
        if header.name is @orderBy
          @objects = _.sortBy(
            @objects
            (item) ->
              # if we need to sort translated col.
              if header.translate
                App.i18n.translateInline(item[header.name])
              # if we need to sort a relation
              if header.relation
                if item[header.name]
                  App[header.relation].find(item[header.name]).displayName()
                else
                  ''
              else
                item[header.name]
          )
          if @orderDirection is 'DESC'
            header.sortOrderIcon = ['arrow-down', 'table-sort-arrow']
            @objects = @objects.reverse()
          else
            header.sortOrderIcon = ['arrow-up', 'table-sort-arrow']
        else
          header.sortOrderIcon = undefined

    # execute header callback
    if @callbackHeader
      for callback in @callbackHeader
        @headers = callback(@headers)

    @headers = @adjustHeaderWidths @headers

    # group by
    if @groupBy

      # get new order
      groupObjects = _.groupBy(
        @objects
        (item) =>
          return '' if !item[@groupBy]
          return item[@groupBy].displayName() if item[@groupBy].displayName
          item[@groupBy]
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
      @objects = []
      for group in groupOrder
        @objects = @objects.concat groupObjects[group]
        groupObjects[group] = [] # release old array

    # get content
    @log 'debug', 'table', 'header', @headers, 'overview', 'objects', @objects
    table = App.view('generic/table')(
      table_id:  @table_id
      header:    @headers
      objects:   @objects
      checkbox:  @checkbox
      radio:     @radio
      groupBy:   @groupBy
      class:     @class
      destroy:   destroy
      callbacks: @callbackAttributes
    )

    # convert to jquery object
    table = $(table)

    cursorMap =
      click:    'pointer'
      dblclick: 'pointer'
      #mouseover: 'alias'

    # bind col.
    if @bindCol
      for name, item of @bindCol
        if item.events
          position = 0
          if @checkbox
            position += 1
          hit      = false

          for headerName in @headers
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
    if @bindRow
      if @bindRow.events
        for event, callback of @bindRow.events
          do (table, event, callback) ->
            if cursorMap[event]
              table.find('tbody > tr').css( 'cursor', cursorMap[event] )
            table.on( event, 'tbody > tr',
              (e) ->
                id = $(e.target).parents('tr').data('id')
                callback(id, e)
            )

    # bind bindCheckbox
    if @bindCheckbox
      if @bindCheckbox.events
        for event, callback of @bindCheckbox.events
          do (table, event, callback) ->
            table.delegate('input[name="bulk"]', event, (e) ->
              e.stopPropagation()
              id      = $(e.target).parents('tr').data('id')
              checked = $(e.target).prop('checked')
              callback(id, checked, e)
            )

    # bind on delete dialog
    if @model && destroy
      table.delegate('[data-type="destroy"]', 'click', (e) =>
        e.stopPropagation()
        e.preventDefault()
        itemId = $(e.target).parents('tr').data('id')
        item   = @model.find(itemId)
        new App.ControllerGenericDestroyConfirm(
          item:      item
          container: @container
        )
      )

    # if we have a personalised table
    if @table_id

      # enable resize column
      table.on 'mousedown', '.js-col-resize', @onColResizeMousedown
      table.on 'click', '.js-col-resize', @stopPropagation

      # enable sort column
      table.on 'click', '.js-sort', @sortByColumn

    # enable checkbox bulk selection
    if @checkbox

      # click first tr>td, catch click
      table.delegate('tr > td:nth-child(1)', event, (e) ->
        e.stopPropagation()
      )

      # bind on full bulk click
      table.delegate('input[name="bulk_all"]', 'change', (e) ->
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

  adjustHeaderWidths: (headers) ->
    availableWidth = @el.width()

    if availableWidth is 0
      availableWidth = @minTableWidth

    widths = @getHeaderWidths headers
    difference = widths - availableWidth

    # convert percentages to pixels
    headers = _.map headers, (col) =>
      unit = col.width.match(/[px|%]+/)[0]

      if unit is '%'
        percentage = parseInt col.width, 10
        col.width = percentage / 100 * availableWidth + 'px'

      return col

    widths = @getHeaderWidths headers
    shrinkBy = Math.ceil (widths - availableWidth) / @getShrinkableHeadersCount(headers)

    # make all cols evenly smaller
    headers = _.map headers, (col) =>
      if !col.unresizable
        value = parseInt col.width, 10
        col.width = Math.max(@minColWidth, value - shrinkBy) + 'px'
      return col

    # give left-over space from rounding to last column to get to 100%
    roundingLeftOver = availableWidth - @getHeaderWidths headers
    # but only if there is something left over (will get negative when there are too many columns for each column to stay in their min width)
    if roundingLeftOver > 0
      headers[headers.length - 1].width = parseInt(headers[headers.length - 1].width, 10) + roundingLeftOver + 'px'

    return headers

  getShrinkableHeadersCount: (headers) ->
    _.reduce headers, (memo, col) ->
      return if col.unresizable then memo else memo+1
    , 0

  getHeaderWidths: (headers) ->
    widths = _.reduce headers, (memo, col, i) =>
      if col.width
        value = parseInt col.width, 10
        unit = col.width.match(/[px|%]+/)[0]
      else
        # !!! sets the width to default width if not set
        headers[i].width = @baseColWidth + 'px'
        value = @baseColWidth
        unit = 'px'

      return if unit is 'px' then memo + value else memo
    , 0

    if @checkbox
      widths += @checkBoxColWidth

    if @radio
      widths += @radioColWidth

    return widths

  onResize: =>
    @headers = @adjustHeaderWidths @headers

    @tableHead.each (i, el) =>
      el.style.width = @headers[i].width

  stopPropagation: (event) =>
    event.stopPropagation()

  onColResizeMousedown: (event) =>
    @resizeTargetLeft = $(event.currentTarget).parents('th')
    @resizeTargetRight = @resizeTargetLeft.next()
    @resizeStartX = event.pageX
    @resizeLeftStartWidth = @resizeTargetLeft.width()
    @resizeRightStartWidth = @resizeTargetRight.width()

    $(document).on 'mousemove.resizeCol', @onColResizeMousemove
    $(document).one 'mouseup', @onColResizeMouseup

    @tableWidth = @el.width()

  onColResizeMousemove: (event) =>
    # use pixels while moving for max precision
    difference = event.pageX - @resizeStartX

    if @resizeLeftStartWidth + difference < @minColWidth
      difference = - (@resizeLeftStartWidth - @minColWidth)

    if @resizeRightStartWidth - difference < @minColWidth
      difference = @resizeRightStartWidth - @minColWidth

    @resizeTargetLeft.width @resizeLeftStartWidth + difference
    @resizeTargetRight.width @resizeRightStartWidth - difference

  onColResizeMouseup: =>
    $(document).off 'mousemove.resizeCol'

    # switch to percentage
    resizeBaseWidth = @resizeTargetLeft.parents('table').width()
    leftWidth = @resizeTargetLeft.outerWidth()
    rightWidth = @resizeTargetRight.outerWidth()

    leftColumnKey = @resizeTargetLeft.attr('data-column-key')
    rightColumnKey = @resizeTargetRight.attr('data-column-key')

    # save table changed widths
    storeColWidths = [
      { key: leftColumnKey, width: leftWidth }
      { key: rightColumnKey, width: rightWidth }
    ]

    @log 'debug', @table_id, 'leftColumnKey', leftColumnKey, leftWidth, 'rightColumnKey', rightColumnKey, rightWidth

    # update store and runtime @headerWidth
    @preferencesStore('headerWidth', leftColumnKey, leftWidth)
    @headerWidth[leftColumnKey] = leftWidth

    # update store and runtime @headerWidth
    if rightColumnKey
      @preferencesStore('headerWidth', rightColumnKey, rightWidth)
      @headerWidth[rightColumnKey] = rightWidth

  sortByColumn: (event) =>
    column = $(event.currentTarget).closest('[data-column-key]').attr('data-column-key')

    # sort, update runtime @orderBy and @orderDirection
    if @orderBy isnt column
      @orderBy = column
      @orderDirection = 'ASC'
    else
      if @orderDirection is 'ASC'
        @orderDirection = 'DESC'
      else
        @orderDirection = 'ASC'

    @log 'debug', @table_id, 'sortByColumn', @orderBy, 'direction', @orderDirection

    # update store
    @preferencesStore('order', 'orderBy', @orderBy)
    @preferencesStore('order', 'orderDirection', @orderDirection)
    @render()

  preferencesStore: (type, key, value) ->
    data = @preferencesGet()
    if !data[type]
      data[type] = {}
    if !data[type][key]
      data[type][key] = {}
    data[type][key] = value
    @log 'debug', @table_id, 'preferencesStore', data
    localStorage.setItem(@preferencesStoreKey(), JSON.stringify(data))

  preferencesGet: =>
    data = localStorage.getItem(@preferencesStoreKey())
    return {} if !data
    @log 'debug', @table_id, 'preferencesGet', data
    JSON.parse(data)

  preferencesStoreKey: =>
    "tablePreferences:#{@table_id}"

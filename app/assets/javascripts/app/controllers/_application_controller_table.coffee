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

  callbackHeader = (headers) ->
    console.log('current header is', headers)
    # add new header item
    attribute =
      name: 'some name'
      display: 'Some Name'
    headers.push attribute
    console.log('new header is', headers)
    headers

  callbackAttributes = (value, object, attribute, header) ->
    console.log('data of item col', value, object, attribute, header)
    value = 'New Data To Show'
    value

  new App.ControllerTable(
    tableId: 'some_id_to_idientify_user_based_table_preferences'
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
    dndCallback: =>
      items = @el.find('table > tbody > tr')
      console.log('all effected items', items)
  )

  new App.ControllerTable(
    el:       element
    overview: ['time', 'area', 'level', 'browser', 'location', 'data']
    attribute_list: [
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
class App.ControllerTable extends App.Controller
  minColWidth: 40
  baseColWidth: 130
  minTableWidth: 612

  checkBoxColWidth: 40
  radioColWidth: 22
  sortableColWidth: 36
  destroyColWidth: 70
  cloneColWidth: 70

  elements:
    '.js-tableHead': 'tableHead'

  events:
    'click .js-sort': 'sortByColumn'

  overviewAttributes: undefined
  #model:             App.TicketPriority,
  objects:            []
  checkbox:           false
  radio:              false
  renderState:        undefined
  groupBy:            undefined
  groupDirection:     undefined

  shownPerPage: 150
  shownPage: 0

  destroy: false

  columnsLength: undefined
  headers: undefined
  headerWidth: {}

  currentRows: []

  orderDirection: 'ASC'
  orderBy: undefined

  lastOrderDirection: undefined
  lastOrderBy: undefined
  lastOverview: undefined

  customOrderDirection: undefined
  customOrderBy: undefined

  frontendTimeUpdateExecute: true

  bindCol: {}
  bindRow: {}

  constructor: ->
    super

    if !@model
      @model = {}
    @overviewAttributes ||= @overview || @model.configure_overview || []
    @attributesListRaw ||= @attribute_list || @model.configure_attributes || {}
    @attributesList = App.Model.attributesGet(false, @attributesListRaw)
    @destroy = @model.configure_delete
    @clone = @model.configure_clone

    throw 'overviewAttributes needed' if _.isEmpty(@overviewAttributes)
    throw 'attributesList needed' if _.isEmpty(@attributesList)

    # apply personal preferences
    data = {}
    if @tableId
      data = @preferencesGet()
      if data.order
        for key, value of data.order
          @[key] = value

    if data.headerWidth
      for key, value of data.headerWidth
        @headerWidth[key] = value

    @availableWidth = @el.width()

    @renderQueue()

  release: =>
    $(window).off 'resize.table', @onResize

  update: (params) =>
    if params.sync is true
      for key, value of params
        @[key] = value
      return @render()
    @renderQueue(params)

  renderQueue: (params) =>
    localeRender = =>
      for key, value of params
        @[key] = value
      @render()
    App.QueueManager.add('tableRender', localeRender)
    App.QueueManager.run('tableRender')

  renderPager: (el, find = false) =>
    pages = parseInt(((@objects.length - 1)  / @shownPerPage))
    if pages < 1
      if find
        el.find('.js-pager').html('')
      else
        el.filter('.js-pager').html('')
      return
    pager = App.view('generic/table_pager')(
      page:  @shownPage
      pages: pages
    )
    if find
      el.find('.js-pager').html(pager)
    else
      el.filter('.js-pager').html(pager)

  render: =>
    @setMaxPage()
    if @renderState is undefined

      # check if table is empty
      if _.isEmpty(@objects)
        @renderState = 'emptyList'
        @el.html(@renderEmptyList())
        $(window).on 'resize.table', @onResize
        return ['emptyList.new']
      else
        @renderState = 'List'
        @renderTableFull()
        $(window).on 'resize.table', @onResize
        return ['fullRender.new']
    else if @renderState is 'emptyList' && !_.isEmpty(@objects)
      @renderState = 'List'
      @renderTableFull()
      return ['fullRender']
    else if @renderState isnt 'emptyList' && _.isEmpty(@objects)
      @renderState = 'emptyList'
      @el.html(@renderEmptyList())
      return ['emptyList']
    else

      # check if header has changed
      if @tableHeadersHasChanged()
        @renderTableFull()
        return ['fullRender.overviewAttributesChanged']

      # check for changes
      newRows = @renderTableRows(true)
      removedRows = _.difference(@currentRows, newRows)
      addedRows = _.difference(newRows, @currentRows)

      @log 'debug', 'table newRows', newRows
      @log 'debug', 'table removedRows', removedRows
      @log 'debug', 'table addedRows', addedRows

      # if only rows are removed
      if (!_.isEmpty(addedRows) || !_.isEmpty(removedRows)) && addedRows.length < 10 && removedRows.length < 15 && removedRows.length < newRows.length && !_.isEmpty(newRows)
        newCurrentRows = []
        removePositions = []
        for position in [0..@currentRows.length-1]
          if _.contains(removedRows, @currentRows[position])
            removePositions.push position
          else
            newCurrentRows.push @currentRows[position]
        addPositions = []
        for position in [0..newRows.length-1]
          if _.contains(addedRows, newRows[position])
            addPositions.push position
            newCurrentRows.splice(position,0,newRows[position])

        # check if order is still correct
        if @_isSame(newRows, newCurrentRows) is true
          for position in removePositions.reverse()
            @$("tbody > tr:nth-child(#{position+1})").remove()
          for position in addPositions
            if position is 0
              if @$('tbody tr:nth-child(1)').get(0)
                @$('tbody tr:nth-child(1)').before(newCurrentRows[position])
              else
                @$('tbody').append(newCurrentRows[position])
            else
              @$("tbody > tr:nth-child(#{position})").after(newCurrentRows[position])
          @currentRows = newCurrentRows
          @log 'debug', 'table.fullRender.contentRemoved', removePositions, addPositions
          @renderPager(@el, true)
          @frontendTimeUpdateElement(@el) if @frontendTimeUpdateExecute is true
          return ['fullRender.contentRemoved', removePositions, addPositions]

      if newRows.length isnt @currentRows.length
        result = ['fullRender.lenghtChanged', @currentRows.length, newRows.length]
        @renderTableFull(newRows)
        @log 'debug', 'table.fullRender.lenghtChanged', result
        return result

      # compare rows
      result = @_isSame(newRows, @currentRows)
      if result isnt true
        @renderTableFull(newRows)
        @log 'debug', "table.fullRender.contentChanged|row(#{result})"
        return ['fullRender.contentChanged', result]

    @log 'debug', 'table.noChanges'
    return ['noChanges']

  renderEmptyList: =>
    App.view('generic/admin/empty')(
      explanation: @explanation
    )

  renderTableFull: (rows) =>
    @log 'debug', 'table.renderTableFull', @orderBy, @orderDirection
    @tableHeaders()
    @sortList()
    bulkIds = @getBulkSelected()
    container = @renderTableContainer()
    if !rows
      rows = @renderTableRows()
      @currentRows = clone(rows)
    else
      @currentRows = clone(rows)
    container.find('.js-tableBody').html(rows)
    @frontendTimeUpdateElement(container) if @frontendTimeUpdateExecute is true

    @renderPager(container)

    cursorMap =
      click:    'pointer'
      dblclick: 'pointer'
      #mouseover: 'alias'

    # bind col.
    if !_.isEmpty(@bindCol)
      for name, item of @bindCol
        if item.events
          position = 0
          if @dndCallback
            position += 1
          if @checkbox
            position += 1
          hit = false

          for headerName in @headers
            if !hit
              position += 1
            if headerName.name is name || headerName.name is "#{name}_id" || headerName.name is "#{name}_bulkIds"
              hit = true

          if hit
            for event, callback of item.events
              do (container, event, callback) ->
                if cursorMap[event]
                  container.find("tbody > tr > td:nth-child(#{position})").css('cursor', cursorMap[event])
                container.on( event, "tbody > tr > td:nth-child(#{position})",
                  (e) ->
                    e.stopPropagation()
                    id = $(e.target).parents('tr').data('id')
                    callback(id, e, e.currentTarget)
                )

    # bind row
    if !_.isEmpty(@bindRow)
      if @bindRow.events
        for event, callback of @bindRow.events
          do (container, event, callback) ->
            if cursorMap[event]
              container.find('tbody > tr').css( 'cursor', cursorMap[event] )
            container.on( event, 'tbody > tr',
              (e) ->
                id = $(e.target).parents('tr').data('id')
                callback(id, e)
            )

    # bind bindCheckbox
    if @bindCheckbox
      if @bindCheckbox.events
        for event, callback of @bindCheckbox.events
          do (container, event, callback) ->
            container.delegate('input[name="bulk"]', event, (e) ->
              e.stopPropagation()
              id      = $(e.currentTarget).parents('tr').data('id')
              checked = $(e.currentTarget).prop('checked')
              callback(id, checked, e)
            )

    # if we have a personalised table
    if @tableId

      # enable resize column
      container.on 'mousedown', '.js-col-resize', @onColResizeMousedown
      container.on 'click', '.js-col-resize', @stopPropagation

    # enable checkbox bulk selection
    if @checkbox

      # click first tr>td, catch click
      container.delegate('tr > td:nth-child(1)', 'click', (e) ->
        e.stopPropagation()
      )

      # bind on full bulk click
      container.delegate('input[name="bulk_all"]', 'change', (e) =>
        e.stopPropagation()
        clicks = []
        if $(e.currentTarget).prop('checked')
          $(e.currentTarget).parents('table').find('[name="bulk"]').each( ->
            $element = $(@)
            return if $element.prop('checked')
            $element.prop('checked', true)
            id = $element.parents('tr').data('id')
            clicks.push [id, true]
          )
        else
          $(e.currentTarget).parents('table').find('[name="bulk"]').each( ->
            $element = $(@)
            return if !$element.prop('checked')
            $element.prop('checked', false)
            id = $element.parents('tr').data('id')
            clicks.push [id, false]
          )
        return if !@bindCheckbox
        return if !@bindCheckbox.events
        return if _.isEmpty(clicks)
        for event, callback of @bindCheckbox.events
          if event == 'click' || event == 'change'
            for click in clicks
              callback(click..., e)
      )

    if @dndCallback
      dndOptions =
        tolerance:            'pointer'
        distance:             15
        opacity:              0.6
        forcePlaceholderSize: true
        items:                'tr'
        helper: (e, tr) ->
          originals = tr.children()
          helper = tr.clone()
          helper.children().each (index) ->
            # Set helper cell sizes to match the original sizes
            $(@).width( originals.eq(index).outerWidth() )
          return helper
        update: @dndCallback
      container.find('tbody').sortable(dndOptions)

    # click on pager
    container.delegate('.js-page', 'click', (e) =>
      e.stopPropagation()
      page = $(e.currentTarget).attr 'data-page'
      render = =>
        @shownPage = page
        @renderTableFull()
      App.QueueManager.add('tableRender', render)
      App.QueueManager.run('tableRender')
    )

    @el.html(container)
    @setBulkSelected(bulkIds)

  renderTableContainer: =>
    $(App.view('generic/table')(
      tableId:    @tableId
      headers:    @headers
      checkbox:   @checkbox
      radio:      @radio
      class:      @class
      sortable:   @dndCallback
    ))

  renderTableRows: (sort = false) =>
    if sort is true
      @sortList()
    position = 0
    columnsLength = @headers.length
    if @checkbox || @radio
      columnsLength++
    groupLast = ''
    groupLastName = ''
    tableBody = []
    objectsToShow = @objectsOfPage(@shownPage)
    for object in objectsToShow
      if object
        position++
        if @groupBy
          groupByName = App.viewPrint(object, @groupBy, @attributesList)
          if groupLastName isnt groupByName
            groupLastName = groupByName
            tableBody.push @renderTableGroupByRow(object, position, groupByName)
        tableBody.push @renderTableRow(object, position)
    tableBody

  renderTableGroupByRow: (object, position, groupByName) =>
    ui_table_group_by_show_count = @Config.get('ui_table_group_by_show_count')
    groupByCount = undefined
    if ui_table_group_by_show_count is true
      groupBy = @groupBy
      groupLast = object[@groupBy]
      if !groupLast
        groupBy = "#{@groupBy}_id"
        groupLast = object[groupBy]
      groupByCount = 0
      if @objects
        for localObject in @objects
          if localObject[groupBy] is groupLast
            groupByCount += 1

    App.view('generic/table_row_group_by')(
      position:      position
      groupByName:   groupByName
      groupByCount:  groupByCount
      columnsLength: @columnsLength
    )

  renderTableRow: (object, position) =>
    App.view('generic/table_row')(
      headers:    @headers
      attributes: @attributesList
      checkbox:   @checkbox
      radio:      @radio
      callbacks:  @callbackAttributes
      sortable:   @dndCallback
      position:   position
      object:     object
      actions:    @actions
    )

  tableHeadersHasChanged: =>
    return true if @overviewAttributes isnt @lastOverview
    false

  tableHeaders: =>
    orderBy = @customOrderBy || @orderBy
    orderDirection = @customOrderDirection || @orderDirection

    if @headers && @lastOrderBy is orderBy && @lastOrderDirection is orderDirection && !@tableHeadersHasChanged()
      @log 'debug', 'table.Headers: same overviewAttributes just return headers', @headers
      return ['headers are the same', @headers]
    @lastOverview = @overviewAttributes

    # get header data
    @headers = []
    @actions = []
    availableWidth = @availableWidth
    for item in @overviewAttributes
      headerFound = false
      for attributeName, attribute of @attributesList

        # remove group by attribute from header
        if !@groupBy || @groupBy isnt item

          if !attribute.style
            attribute.style = {}

          if attributeName is item
            # e.g. column: owner
            headerFound = true
            if @headerWidth[attribute.name]
              attribute.displayWidth = @headerWidth[attribute.name] * availableWidth
            else if !attribute.width
              attribute.displayWidth = @baseColWidth
            else
              # convert percentages to pixels
              value = parseInt attribute.width, 10
              unit = attribute.width.match(/[px|%]+/)[0]

              if unit is '%'
                attribute.displayWidth = value / 100 * availableWidth
              else
                attribute.displayWidth = value
            @headers.push attribute
          else
            # e.g. column: owner_id or owner_ids
            if attributeName is "#{item}_id" || attributeName is "#{item}_ids"
              headerFound = true
              if @headerWidth[attribute.name]
                attribute.displayWidth = @headerWidth[attribute.name] * availableWidth
              else if !attribute.width
                attribute.displayWidth = @baseColWidth
              else
                # convert percentages to pixels
                value = parseInt attribute.width, 10
                unit = attribute.width.match(/[px|%]+/)[0]

                if unit is '%'
                  attribute.displayWidth = value / 100 * availableWidth
                else
                  attribute.displayWidth = value
              @headers.push attribute


    # execute header callback
    if @callbackHeader
      for callback in @callbackHeader
        @headers = callback(@headers)

    throw 'no headers found' if _.isEmpty(@headers)

    if @clone
      @actions.push
        name: 'clone'
        display: 'Clone'
        icon: 'clipboard'
        class: 'create  js-clone'
        callback: (id) =>
          item = @model.find(id)
          item.name = "Clone: #{item.name}"
          new App.ControllerGenericNew(
            item: item
            pageData:
              object: item.constructor.className
            callback: =>
              @renderTableFull()
            genericObject: item.constructor.className
            container:     @container
          )

    if @destroy
      @actions.push
        name: 'delete'
        display: 'Delete'
        icon: 'trash'
        class: 'danger js-delete'
        callback: (id) =>
          item = @model.find(id)
          new App.ControllerGenericDestroyConfirm
            item:      item
            container: @container

    if @actions.length
      @headers.push
        name: 'action'
        display: 'Action'
        width: '38px'
        displayWidth: 38
        unresizeable: true
        align: 'right'
        parentClass: 'noTruncate no-padding'

      @bindCol['action'] =
        events:
          click: @toggleActionDropdown

    if @tableId
      @calculateHeaderWidths()

    @columnsLength = @headers.length
    if @checkbox || @radio
      @columnsLength++
    @log 'debug', 'table.Headers: new headers', @headers
    ['new headers', @headers]

  setMaxPage: =>
    pages = parseInt(((@objects.length - 1)  / @shownPerPage))
    if parseInt(@shownPage) > pages
      @shownPage = pages

  objectsOfPage: (page = 0) =>
    page = parseInt(page)
    @objects.slice(page * @shownPerPage, (page + 1) * @shownPerPage)

  sortList: =>
    return if _.isEmpty(@objects)

    orderBy = @customOrderBy || @orderBy
    orderDirection = @customOrderDirection || @orderDirection

    @log 'debug', 'table.order', @orderBy, @orderDirection
    @log 'debug', 'table.customOrder', @customOrderBy, @customOrderDirection

    return if _.isEmpty(orderBy) && _.isEmpty(@groupBy)

    return if @lastSortedobjects is @objects && @lastOrderDirection is orderDirection && @lastOrderBy is orderBy
    @lastOrderDirection = orderDirection
    @lastOrderBy = orderBy

    localObjects is undefined
    if orderBy
      for header in @headers
        if header.name is orderBy || "#{header.name}_id" is orderBy || header.name is "#{orderBy}_id"
          localObjects = _.sortBy(
            @objects
            (item) ->

              # error handling
              if !item
                console.log('Got empty object in order by with header _.sortBy')
                return ''

              # if we need to sort translated col.
              if header.translate
                return App.i18n.translateInline(item[header.name])

              # if we need to sort by relation name
              if header.relation
                if item[header.name]
                  localItem = App[header.relation].findNative(item[header.name])
                  if localItem
                    if localItem.displayName
                      localItem = localItem.displayName().toLowerCase()
                    if localItem.name
                      localItem = localItem.name.toLowerCase()
                    return localItem
                return ''
              item[header.name]
          )
          if orderDirection is 'DESC'
            header.sortOrderIcon = ['arrow-down', 'table-sort-arrow']
            localObjects = localObjects.reverse()
          else
            header.sortOrderIcon = ['arrow-up', 'table-sort-arrow']
        else
          header.sortOrderIcon = undefined

      # in case order by is not in show column, use orderBy attribute
      if !localObjects
        for attributeName, attribute of @attributesList
          if attributeName is orderBy || "#{attributeName}_id" is orderBy || attributeName is "#{orderBy}_id"

            # order by
            localObjects = _.sortBy(
              @objects
              (item) ->

                # error handling
                if !item
                  console.log('Got empty object in order by in attribute _.sortBy')
                  return ''

                # if we need to sort translated col.
                if attribute.translate
                  return App.i18n.translateInline(item[attribute.name])

                # if we need to sort by relation name
                if attribute.relation
                  if item[attribute.name]
                    localItem = App[attribute.relation].findNative(item[attribute.name])
                    if localItem
                      if localItem.displayName
                        localItem = localItem.displayName().toLowerCase()
                      if localItem.name
                        localItem = localItem.name.toLowerCase()
                      return localItem
                  return ''
                item[attribute.name]
            )
            if orderDirection is 'DESC'
              localObjects = localObjects.reverse()

      if localObjects
        @objects = localObjects
      else
        console.log("Unable to orderBy objects, no attribute found with name #{orderBy}")

    # group by
    if @groupBy

      # get groups
      groupObjects = {}
      for object in @objects
        group = object[@groupBy]
        if !group
          withId = "#{@groupBy}_id"
          if object[withId] && @attributesList[withId] && @attributesList[withId].relation
            if App[@attributesList[withId].relation].exists(object[withId])
              item = App[@attributesList[withId].relation].findNative(object[withId])
              if item && item.displayName
                group = item.displayName().toLowerCase()
              else if item.name
                group = item.name.toLowerCase()
        if _.isEmpty(group)
          group = ''
        if group.displayName
          group = group.displayName().toLowerCase()
        else if group.name
          group = group.name.toLowerCase()
        groupObjects[group] ||= []
        groupObjects[group].push object

      groupsSorted = []
      for key of groupObjects
        groupsSorted.push key
      groupsSorted = groupsSorted.sort()
      # Reverse the sorted groups depending on the groupDirection
      if @groupDirection == 'DESC'
        groupsSorted.reverse()

      # get new order
      localObjects = []
      for group in groupsSorted
        localObjects = localObjects.concat groupObjects[group]
        groupObjects[group] = [] # release old array

    return if localObjects is undefined
    @objects = localObjects
    @lastSortedobjects = localObjects

  onActionButtonClicked: (e) =>
    id = $(e.currentTarget).parents('tr').data('id')
    name = e.currentTarget.getAttribute('data-table-action')
    @runAction(name, id)
    console.log 'onActionButtonClicked'

  runAction: (name, id) =>
    action = _.findWhere @actions, name: name
    action.callback(id)

  toggleActionDropdown: (id, e, td) =>
    e.stopPropagation()
    $dropdown = $(td).find('.js-table-action-menu')
    if $dropdown.length
      # open dropdown
      $dropdown.dropdown('toggle')
      # bind on click now that the dropdown is open
      $dropdown.one('click.dropdown', '[data-table-action]', @onActionButtonClicked)
      # unbind after dropdown is closed
      $dropdown.parent().one('hide.bs.dropdown', -> $dropdown.off('click.dropdown'))
    else
      # only one action - directly fire that action
      name = $(td).find('[data-table-action]').attr('data-table-action')
      @runAction(name, id)

  calculateHeaderWidths: ->
    return if !@headers

    if @availableWidth is 0
      @availableWidth = @minTableWidth

    availableWidth = @availableWidth

    widths = @getHeaderWidths()
    shrinkBy = Math.ceil (widths - availableWidth) / @getShrinkableHeadersCount()

    # make all cols evenly smaller
    @headers = _.map @headers, (col) =>
      if !col.unresizable
        col.displayWidth = Math.max(@minColWidth, col.displayWidth - shrinkBy)
      return col

    # give left-over space from rounding to last column to get to 100%
    roundingLeftOver = availableWidth - @getHeaderWidths()

    # but only if there is something left over (will get negative when there are too many columns for each column to stay in their min width)
    if roundingLeftOver > 0
      @headers[@headers.length - 1].displayWidth = @headers[@headers.length - 1].displayWidth + roundingLeftOver

    @storeHeaderWidths()

  getShrinkableHeadersCount: ->
    _.reduce @headers, (memo, col) ->
      return if col.unresizable then memo else memo+1
    , 0

  getHeaderWidths: ->
    widths = _.reduce @headers, (memo, col, i) ->
      return memo + col.displayWidth
    , 0

    if @checkbox
      widths += @checkBoxColWidth

    if @radio
      widths += @radioColWidth

    if @dndCallback
      widths += @sortableColWidth

    if @destroy
      widths += @destroyColWidth

    if @clone
      widths += @cloneColWidth

    widths

  setHeaderWidths: =>
    @calculateHeaderWidths()

    @tableHead.each (i, el) =>
      el.style.width = @headers[i].displayWidth + 'px'

  storeHeaderWidths: ->
    widths = {}

    for header in @headers
      widths[header.name] = header.displayWidth / @availableWidth

    App.LocalStorage.set(@preferencesStoreKey(), { headerWidth: widths }, @Session.get('id'))

  onResize: =>
    @availableWidth = @el.width()
    @setHeaderWidths()

  stopPropagation: (event) ->
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
    leftWidth = @resizeTargetLeft.width() / resizeBaseWidth
    rightWidth = @resizeTargetRight.width() / resizeBaseWidth

    leftColumnKey = @resizeTargetLeft.attr('data-column-key')
    rightColumnKey = @resizeTargetRight.attr('data-column-key')

    # update store and runtime @headerWidth
    @preferencesStore('headerWidth', leftColumnKey, leftWidth)
    @headerWidth[leftColumnKey] = leftWidth

    # set header at runtime
    for header in @headers
      if header.name is leftColumnKey
        header.displayWidth = @resizeTargetLeft.outerWidth()

    # update store and runtime @headerWidth
    if rightColumnKey
      @preferencesStore('headerWidth', rightColumnKey, rightWidth)
      @headerWidth[rightColumnKey] = rightWidth

      # set header at runtime
      for header in @headers
        if header.name is rightColumnKey
          header.displayWidth = @resizeTargetRight.outerWidth()

  sortByColumn: (event) =>
    column = $(event.currentTarget).closest('[data-column-key]').attr('data-column-key')

    orderBy = @customOrderBy || @orderBy
    orderDirection = @customOrderDirection || @orderDirection

    # sort, update runtime @orderBy and @orderDirection
    if orderBy isnt column
      orderBy = column
      orderDirection = 'ASC'
    else
      if orderDirection is 'ASC'
        orderDirection = 'DESC'
      else
        orderDirection = 'ASC'

    @orderBy = orderBy
    @orderDirection = orderDirection
    @customOrderBy = orderBy
    @customOrderDirection = orderDirection

    # update store
    @preferencesStore('order', 'customOrderBy', @orderBy)
    @preferencesStore('order', 'customOrderDirection', @orderDirection)
    render = =>
      @renderTableFull()
    App.QueueManager.add('tableRender', render)
    App.QueueManager.run('tableRender')

  preferencesStore: (type, key, value) ->
    data = @preferencesGet()
    if !data[type]
      data[type] = {}
    if !data[type][key]
      data[type][key] = {}
    data[type][key] = value

    App.LocalStorage.set(@preferencesStoreKey(), data, @Session.get('id'))

  preferencesGet: =>
    data = App.LocalStorage.get(@preferencesStoreKey(), @Session.get('id'))
    return {} if !data
    data

  preferencesStoreKey: =>
    "tablePrefs:#{@tableId}"

  getBulkSelected: =>
    ids = []
    @$('[name="bulk"]:checked').each( (index, element) ->
      id = $(element).val()
      ids.push id
    )
    ids

  setBulkSelected: (ids) ->
    @$('[name="bulk"]').each( (index, element) ->
      id = $(element).val()
      for idSelected in ids
        if idSelected is id
          $(element).prop('checked', true)
    )

  _isSame: (array1, array2) ->
    for position in [0..array1.length-1]
      if array1[position] isnt array2[position]
        return position
    true
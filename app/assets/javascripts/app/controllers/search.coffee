class App.Search extends App.Controller
  @extend App.PopoverProvidable
  @extend App.TicketMassUpdatable

  elements:
    '.js-search': 'searchInput'

  events:
    'click .js-emptySearch': 'empty'
    'submit form.search-holder': 'preventDefault'
    'keyup .js-search': 'listNavigate'
    'click .js-tab': 'showTab'
    'input .js-search': 'updateFilledClass'

  @include App.ValidUsersForTicketSelectionMethods

  constructor: ->
    super

    # check authentication
    @authenticateCheckRedirect()

    current = App.TaskManager.get(@taskKey).state
    if current && current.query
      @query = current.query

    # update taskbar with new meta data
    App.TaskManager.touch(@taskKey)

    @globalSearch = new App.GlobalSearch(
      render: @renderResult
      limit: 50
    )

    @render()

    # rerender view, e. g. on langauge change
    @controllerBind('ui:rerender', =>
      @render()
    )

    load = (data) =>
      App.Collection.loadAssets(data.assets)
      @formMeta = data.form_meta
    @bindId = App.TicketOverviewCollection.bind(load)

  meta: =>
    title = @query || App.i18n.translateInline('Extended Search')

    meta =
      url:   @url()
      id:    ''
      head:  title
      title: title
      iconClass: 'searchdetail'
    meta

  url: ->
    '#search'

  show: (params) =>
    if @table
      @table.show()
    @navupdate(url: '#search', type: 'menu')

    if !_.isEmpty(params.query)
      @$('.js-search').val(params.query).trigger('keyup')
      return

    if @query
      @search(500, true)

  hide: ->
    @saveOrderBy()
    if @table
      @table.hide()

  changed: ->
    # nothing

  render: ->
    currentState = App.TaskManager.get(@taskKey).state
    if !@query
      if currentState && currentState.query
        @query = currentState.query

    if !@model
      if currentState && currentState.model
        @model = currentState.model
      else
        @model = 'Ticket'

    @tabs = []
    for model in App.Config.get('models_searchable')
      model = model.replace(/::/g, '')
      tab =
        name: App[model]?.display_name || model
        model: model
        count: 0
        active: false
      if @model == model
        tab.active = true
      @tabs.push tab

    # build view
    elLocal = $(App.view('search/index')(
      query: @query
      tabs: @tabs
    ))

    @controllerTicketBatch.releaseController() if @controllerTicketBatch
    @controllerTicketBatch = new App.TicketBatch(
      el:       elLocal.filter('.js-batch-overlay')
      parent:   @
      parentEl: elLocal
      appEl:    @appEl
      batchSuccess: =>
        @search(0, true)
    )

    @html elLocal
    if @query
      @search(500, true)

  listNavigate: (e) =>
    if e.keyCode is 27 # close on esc
      @empty()
      return

    # on other keys, show result
    @navigate "#search/#{encodeURIComponent(@searchInput.val())}"
    @savedOrderBy = null
    @search(0)

  empty: =>
    @searchInput.val('')
    @query = ''
    @updateFilledClass()
    @updateTask()

    @delayedRemoveAnyPopover()

  search: (delay, force = false) =>
    query = @searchInput.val().trim()
    if !force
      return if !query
      return if query is @query
    @query = query
    @updateTask()

    if delay is 0
      delay = 500
      if query.length > 2
        delay = 350
      else if query.length > 4
        delay = 200

    @globalSearch.search(
      delay: delay
      query: @query
      force: force
    )

  renderResult: (result = []) =>
    @result = result
    for tab in @tabs
      count = 0
      if result[tab.model]
        count = result[tab.model].length
      if @model is tab.model
        @renderTab(tab.model, result[tab.model] || [])
      @$(".js-tab#{tab.model} .js-counter").text(count)

  showTab: (e) =>
    @saveOrderBy()
    tabs = $(e.currentTarget).closest('.tabs')
    tabModel = $(e.currentTarget).data('tab-content')
    tabs.find('.js-tab').removeClass('active')
    $(e.currentTarget).addClass('active')
    @renderTab(tabModel, @result?[tabModel] || [])

  renderTab: (model, localList) =>

    # remember last shown model
    if @model isnt model
      @model = model
      @updateTask()

    list = []
    for item in localList
      object = App[model].fullLocal(item.id)
      list.push object
    if model is 'Ticket'

      openTicket = (id,e) =>
        # open ticket via task manager to provide task with overview info
        ticket = App.Ticket.findNative(id)
        App.TaskManager.execute(
          key:        "Ticket-#{ticket.id}"
          controller: 'TicketZoom'
          params:
            ticket_id:   ticket.id
            overview_id: @overview.id
          show:       true
        )
        @navigate ticket.uiUrl()

      checkbox = @permissionCheck('ticket.agent') ? true : false

      callbackCheckbox = (id, checked, e) =>
        if @shouldShowBulkForm()
          @bulkForm.render()
          @bulkForm.show()
        else
          @bulkForm.hide()

        if @lastChecked && e.shiftKey
          # check items in a row
          currentItem = $(e.currentTarget).parents('.item')
          lastCheckedItem = $(@lastChecked).parents('.item')
          items = currentItem.parent().children()

          if currentItem.index() > lastCheckedItem.index()
            # current item is below last checked item
            startId = lastCheckedItem.index()
            endId = currentItem.index()
          else
            # current item is above last checked item
            startId = currentItem.index()
            endId = lastCheckedItem.index()

          items.slice(startId+1, endId).find('[name="bulk"]').prop('checked', (-> !@checked))

        @lastChecked = e.currentTarget
        @bulkForm.updateTicketIdsBulkForm(e)

      ticket_ids = []
      for item in localList
        ticket_ids.push item.id
      localeEl = @$('.js-content')
      @table = new App.TicketList(
        tableId:    "find_#{model}"
        el:         localeEl
        columns:    [ 'number', 'title', 'customer', 'group', 'owner', 'created_at' ]
        ticket_ids: ticket_ids
        radio:      false
        checkbox:   checkbox
        orderBy:        @getSavedOrderBy('Ticket')?.order
        orderDirection: @getSavedOrderBy('Ticket')?.direction
        bindRow:
          events:
            'click': openTicket
        bindCheckbox:
          events:
            'click': callbackCheckbox
          select_all: callbackCheckbox
      )

      updateSearch = =>
        callback = =>
          @search(0, true)
        @delay(callback, 100)

      @bulkForm.releaseController() if @bulkForm
      @bulkForm = new App.TicketBulkForm(
        el:           @el.find('.bulkAction')
        holder:       localeEl
        view:         @view
        batchSuccess: updateSearch
        noSidebar:    true
      )

      # start bulk action observ
      localElement = @$('.js-content')
      if localElement.find('input[name="bulk"]:checked').length isnt 0
        @bulkForm.show()

      # show/hide bulk action
      localElement.on('change', 'input[name="bulk"], input[name="bulk_all"]', (e) =>
        if @shouldShowBulkForm()
          @bulkForm.show()
        else
          @bulkForm.hide()
          @bulkForm.reset()
      )

      # deselect bulk_all if one item is uncheck observ
      localElement.on('change', '[name="bulk"]', (e) ->
        bulkAll = localElement.find('[name="bulk_all"]')
        checkedCount = localElement.find('input[name="bulk"]:checked').length
        checkboxCount = localElement.find('input[name="bulk"]').length
        if checkedCount is 0
          bulkAll.prop('indeterminate', false)
          bulkAll.prop('checked', false)
        else
          if checkedCount is checkboxCount
            bulkAll.prop('indeterminate', false)
            bulkAll.prop('checked', true)
          else
            bulkAll.prop('checked', false)
            bulkAll.prop('indeterminate', true)
      )
    else
      openObject = (id,e) =>
        object = App[@model].fullLocal(id)
        @navigate object.uiUrl()
      @table = new App.ControllerTable(
        orderBy: @getSavedOrderBy(model)?.order
        orderDirection: @getSavedOrderBy(model)?.direction
        tableId: "find_#{model}"
        el:      @$('.js-content')
        model:   App[model]
        objects: list
        bindRow:
          events:
            'click': openObject
      )

  updateTask: =>
    current = App.TaskManager.get(@taskKey).state
    return if !current
    current.query = @query
    current.model = @model
    App.TaskManager.update(@taskKey, { state: current })
    App.TaskManager.touch(@taskKey)

  updateFilledClass: ->
    @searchInput.toggleClass 'is-empty', !@searchInput.val()

  shouldShowBulkForm: =>
    items = @$('table').find('input[name="bulk"]:checked')
    return false if items.length == 0

    ticket_ids        = _.map(items, (el) -> $(el).val() )
    ticket_group_ids  = _.map(App.Ticket.findAll(ticket_ids), (ticket) -> ticket.group_id)
    ticket_group_ids  = _.uniq(ticket_group_ids)
    allowed_group_ids = App.User.find(@Session.get('id')).allGroupIds('change')
    allowed_group_ids = _.map(allowed_group_ids, (id_string) -> parseInt(id_string, 10) )
    _.every(ticket_group_ids, (id) -> id in allowed_group_ids)

  getSavedOrderBy: (model) =>
    return if !@savedOrderBy

    @savedOrderBy[model]

  saveOrderBy: =>
    return if !@table
    table = @table.table || @table
    model = table.model.name

    @savedOrderBy ||= {}
    @savedOrderBy[model] = { order: table.lastOrderBy, direction: table.lastOrderDirection }

class Router extends App.ControllerPermanent
  constructor: (params) ->
    super

    query = undefined
    if !_.isEmpty(params.query)
      query = decodeURIComponent(params.query)

    # cleanup params
    clean_params =
      query: query

    App.TaskManager.execute(
      key:        'Search'
      controller: 'Search'
      params:     clean_params
      show:       true
    )

App.Config.set('search', Router, 'Routes')
App.Config.set('search/:query', Router, 'Routes')

class App.TicketOverview extends App.Controller
  @extend App.TicketMassUpdatable
  @include App.ValidUsersForTicketSelectionMethods

  className: 'overviews'
  activeFocus: 'nav'

  elements:
    '.main': 'mainContent'

  constructor: ->
    super
    @render()

    load = (data) =>
      App.Collection.loadAssets(data.assets)
      @formMeta = data.form_meta
    @bindId = App.TicketOverviewCollection.bind(load)

  render: ->
    elLocal = $(App.view('ticket_overview/index')())

    @navBarControllerVertical.releaseController() if @navBarControllerVertical
    @navBarControllerVertical = new App.TicketOverviewNavbar(
      el:       elLocal.find('.overview-header')
      view:     @view
      vertical: true
    )

    @navBarController.releaseController() if @navBarController
    @navBarController = new App.TicketOverviewNavbar(
      el:   elLocal.filter('.sidebar')
      view: @view
    )

    @contentController.releaseController() if @contentController
    @contentController = new App.TicketOverviewTable(
      el:          elLocal.find('.overview-table')
      view:        @view
      keyboardOn:  @keyboardOn
      keyboardOff: @keyboardOff
    )

    if App.User.current().permission('ticket.agent')
      @controllerTicketBatch.releaseController() if @controllerTicketBatch
      @controllerTicketBatch = new App.TicketBatch(
        el:           elLocal.filter('.js-batch-overlay')
        parent:       @
        parentEl:     elLocal
        appEl:        @appEl
        batchSuccess: =>
          @contentController.render()
      )

    @html elLocal

    @$('.main').on('click', =>
      @activeFocus = 'overview'
    )
    @$('.sidebar').on('click', =>
      @activeFocus = 'nav'
    )

    @controllerBind('overview:fetch', =>
      return if !@view
      update = =>
        App.OverviewListCollection.fetch(@view)
      @delay(update, 2800, 'overview:fetch')
    )

  active: (state) =>
    return @shown if state is undefined
    @shown = state

  url: =>
    "#ticket/view/#{@view}"

  show: (params) =>
    @keyboardOn()

    # highlight navbar
    @navupdate '#ticket/view'

    # redirect to last overview if we got called in first level
    @view = params['view']
    if !@view && @viewLast
      @navigate "#ticket/view/#{@viewLast}", { hideCurrentLocationFromHistory: true }
      return

    # build nav bar
    if @navBarController
      @navBarController.update(
        view:        @view
        activeState: true
      )

    if @navBarControllerVertical
      @navBarControllerVertical.update(
        view:        @view
        activeState: true
      )

    # do not rerender overview if current overview is requested again
    if @viewLast is @view
      if @contentController
        @contentController.show()
      return

    # remember last view
    @viewLast = @view

    # build content
    @contentController.releaseController() if @contentController
    @contentController = new App.TicketOverviewTable(
      el:          @$('.overview-table')
      view:        @view
      keyboardOn:  @keyboardOn
      keyboardOff: @keyboardOff
    )

  hide: =>
    @keyboardOff()

    if @navBarController
      @navBarController.active(false)
    if @navBarControllerVertical
      @navBarControllerVertical.active(false)
    if @contentController
      @contentController.hide()

  setPosition: (position) =>
    @$('.main').scrollTop(position)

  currentPosition: =>
    @$('.main').scrollTop()

  changed: ->
    false

  release: =>
    @keyboardOff()
    super
    App.TicketOverviewCollection.unbindById(@bindId)

  keyboardOn: =>
    $(window).off 'keydown.overview_navigation'
    $(window).on 'keydown.overview_navigation', @listNavigate

  keyboardOff: ->
    $(window).off 'keydown.overview_navigation'

  listNavigate: (e) =>

    # ignore if focus is in bulk action
    return if $(e.target).is('textarea, input, select')

    if e.keyCode is 38 # up
      e.preventDefault()
      @nudge(e, -1)
      return
    else if e.keyCode is 40 # down
      e.preventDefault()
      @nudge(e, 1)
      return
    else if e.keyCode is 32 # space
      e.preventDefault()
      if @activeFocus is 'overview'
        @$('.table-overview table tbody tr.is-hover td.js-checkbox-field label input').first().trigger('click')
    else if e.keyCode is 9 # tab
      e.preventDefault()
      if @activeFocus is 'nav'
        @activeFocus = 'overview'
        @nudge(e, 1)
      else
        @activeFocus = 'nav'
    else if e.keyCode is 13 # enter
      if @activeFocus is 'overview'
        location = @$('.table-overview table tbody tr.is-hover a').first().attr('href')
        if location
          @navigate location

  nudge: (e, position) ->

    if @activeFocus is 'overview'
      items = @$('.table-overview table tbody')
      current = items.find('tr.is-hover')

      if !current.length
        items.find('tr').first().addClass('is-hover')
        return

      if position is 1
        next = current.next('tr')
        if next.length
          current.removeClass('is-hover')
          next.addClass('is-hover')
      else
        prev = current.prev('tr')
        if prev.length
          current.removeClass('is-hover')
          prev.addClass('is-hover')

      if next
        @scrollToIfNeeded(next, true)
      if prev
        @scrollToIfNeeded(prev, true)

    else
      # get current
      items = @$('.sidebar')
      current = items.find('li.active')

      if !current.length
        location = items.find('li a').first().attr('href')
        if location
          @navigate location
        return

      if position is 1
        next = current.next('li')
        if next.length
          @navigate next.find('a').attr('href')
      else
        prev = current.prev('li')
        if prev.length
          @navigate prev.find('a').attr('href')

      if next
        @scrollToIfNeeded(next, true)
      if prev
        @scrollToIfNeeded(prev, true)

class TicketOverviewRouter extends App.ControllerPermanent
  @requiredPermission: ['ticket.agent', 'ticket.customer']

  constructor: (params) ->
    super

    # check authentication
    @authenticateCheckRedirect()

    # cleanup params
    clean_params =
      view: params.view
      appEl: params.appEl

    App.TaskManager.execute(
      key:        'TicketOverview'
      controller: 'TicketOverview'
      params:     clean_params
      show:       true
      persistent: true
    )

App.Config.set('ticket/view', TicketOverviewRouter, 'Routes')
App.Config.set('ticket/view/:view', TicketOverviewRouter, 'Routes')
App.Config.set('TicketOverview', { controller: 'TicketOverview', permission: ['ticket.agent', 'ticket.customer'] }, 'permanentTask')
App.Config.set('TicketOverview', { prio: 1000, parent: '', name: __('Overviews'), target: '#ticket/view', key: 'TicketOverview', permission: ['ticket.agent', 'ticket.customer'], class: 'overviews' }, 'NavBar')

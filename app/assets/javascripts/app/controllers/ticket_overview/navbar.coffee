class App.TicketOverviewNavbar extends App.Controller
  elements:
    '.js-tabsHolder': 'tabsHolder'
    '.js-tabsClone': 'clone'
    '.js-tabClone': 'tabClone'
    '.js-tabs': 'tabs'
    '.js-tab': 'tab'
    '.js-dropdown': 'dropdown'
    '.js-toggle': 'dropdownToggle'
    '.js-dropdownItem': 'dropdownItem'

  events:
    'click .js-tab': 'activate'
    'click .js-dropdownItem': 'navigateTo'
    'hide.bs.dropdown': 'onDropdownHide'
    'show.bs.dropdown': 'onDropdownShow'

  constructor: ->
    super

    @bindId = App.OverviewIndexCollection.bind(@render)

    # rerender view, e. g. on language change
    @controllerBind('ui:rerender', =>
      @render(App.OverviewIndexCollection.get())
    )
    if @vertical
      $(window).on 'resize.navbar', @autoFoldTabs

  navigateTo: (event) ->
    location.hash = $(event.currentTarget).attr('data-target')

  onDropdownShow: =>
    @dropdownToggle.addClass('active')

  onDropdownHide: =>
    @dropdownToggle.removeClass('active')

  activate: (event) =>
    @tab.removeClass('active')
    $(event.currentTarget).addClass('active')

  release: =>
    if @vertical
      $(window).off 'resize.navbar', @autoFoldTabs
    App.OverviewIndexCollection.unbindById(@bindId)

  autoFoldTabs: =>
    items = App.OverviewIndexCollection.get()

    return if not items

    if App.UserOverviewSorting.count()
      items.sort(App.UserOverviewSortingOverview.overviewSort)
    else
      items.sort((a, b) -> a.prio - b.prio)

    @html App.view("agent_ticket_view/navbar#{ if @vertical then '_vertical' }")
      items: items
      isAgent: @permissionCheck('ticket.agent')

    while @clone.width() > @tabsHolder.width()
      @tabClone.not('.hide').last().addClass('hide')
      @tab.not('.hide').last().addClass('hide')
      @dropdownItem.filter('.hide').last().removeClass('hide')

    # if all tabs are visible
    # remove dropdown and dropdown button
    if @dropdownItem.not('.hide').length is 0
      @dropdown.remove()
      @dropdownToggle.remove()

  active: (state) =>
    @activeState = state

  update: (params = {}) ->
    for key, value of params
      @[key] = value
    @render(App.OverviewIndexCollection.get())

  render: (data) =>
    return if !data
    content = @el.closest('.content')
    if _.isArray(data) && _.isEmpty(data)
      content.find('.sidebar').addClass('hide')
      content.find('.main').addClass('hide')
      content.find('.js-error').removeClass('hide')
      @renderScreenError(
        el: @el.closest('.content').find('.js-error')
        detail:     __('Currently no overview is assigned to your roles. Please contact your administrator.')
        objectName: 'Ticket'
      )
      return
    content.find('.sidebar').removeClass('hide')
    content.find('.main').removeClass('hide')
    content.find('.js-error').addClass('hide')

    # do not show vertical navigation if only one tab exists
    if @vertical
      if data && data.length <= 1
        @el.addClass('hidden')
      else
        @el.removeClass('hidden')

    # set page title
    if @activeState && @view && !@vertical
      for item in data
        if item.link is @view
          @title item.name, true

    # send first view info
    if !@view && data && data[0] && data[0].link
      App.WebSocket.send(event:'ticket_overview_select', data: { view: data[0].link })

    # redirect to first view
    if @activeState && !@view && !@vertical
      view = data[0].link
      @navigate "#ticket/view/#{view}", { hideCurrentLocationFromHistory: true }
      return

    # add new views
    for item in data
      item.target = "#ticket/view/#{item.link}"
      if item.link is @view
        item.active = true
        activeOverview = item
      else
        item.active = false

    # sort by profile preferences
    if App.UserOverviewSorting.count()
      data.sort(App.UserOverviewSortingOverview.overviewSort)
    else
      data.sort((a, b) -> a.prio - b.prio)

    @html App.view("agent_ticket_view/navbar#{ if @vertical then '_vertical' else '' }")
      items: data

    if @vertical
      @autoFoldTabs()

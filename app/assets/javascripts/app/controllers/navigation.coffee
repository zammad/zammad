class App.Navigation extends App.ControllerWidgetPermanent
  className: 'navigation vertical'

  elements:
    '#global-search': 'searchInput'
    '.search': 'searchContainer'
    '.js-global-search-result': 'searchResult'
    '.js-details-link': 'searchDetails'

  events:
    'click .js-toggleNotifications': 'toggleNotifications'
    'click .js-emptySearch': 'emptyAndClose'
    'submit form.search-holder': 'preventDefault'
    'dblclick form.search-holder .icon-magnifier': 'openExtendedSearch'
    'focus #global-search': 'searchFocus'
    'blur #global-search': 'searchBlur'
    'keyup #global-search': 'listNavigate'
    'click .js-global-search-result': 'andClose'
    'click .js-details-link': 'openExtendedSearch'
    'change .js-menu .js-switch input': 'switch'

  constructor: ->
    super
    @render()

    @throttledSearch = _.throttle @search, 200

    @globalSearch = new App.GlobalSearch(
      render: @renderResult
    )

    # rerender view, e. g. on langauge change
    @bind 'ui:rerender', =>
      @renderMenu()
      @renderPersonal()

    # rerender menu
    @bind 'menu:render', =>
      @renderMenu()

    # rerender menu
    @bind 'personal:render', =>
      @renderPersonal()

    # update selected item
    @bind 'navupdate', (params) =>
      @update(params)

    # rebuild nav bar with given user data
    @bind 'auth', (user) =>
      @render()

    # fetch new recent viewed after collection change
    @bind 'RecentView::changed', =>
      @delay(
        => @fetchRecentView()
        1000
        'recent-view-changed'
      )

    # bell on / bell off
    @bind 'bell', (data) =>
      if data is 'on'
        @$('.bell').addClass('show')
        App.Audio.play( 'https://www.sounddogs.com/previews/2193/mp3/219024_SOUNDDOGS__be.mp3' )
        @delay(
          -> App.Event.trigger('bell', 'off')
          3000
        )
      else
        @$('.bell').removeClass('show')

  release: =>
    if @notificationWidget
      @notificationWidget.remove()
      @notificationWidget = undefined

  renderMenu: =>
    items = @getItems(navbar: @Config.get('NavBar'))

    # apply counter and switch info from persistant controllers (if exists)
    activeTab = {}
    itemsNew = []
    for item in items
      shown = true
      if item.shown isnt undefined
        shown = item.shown
      if item.key
        worker = App.TaskManager.worker(item.key)
        if worker
          if worker.counter
            item.counter = worker.counter()
          if worker.switch
            item.switch = worker.switch()
          if worker.active && worker.active()
            activeTab[item.target] = true
          if worker.featureActive
            if worker.featureActive()
              shown = true
            else
              shown = false
      if shown
        itemsNew.push item
    items = itemsNew

    # get open tabs to repopen on rerender
    openTab = {}
    @$('.open').children('a').each( (i,d) ->
      href = $(d).attr('href')
      openTab[href] = true
    )

    # render menu
    @$('.js-menu').html App.view('navigation/menu')(
      items:     items
      openTab:   openTab
      activeTab: activeTab
    )

  #  on switch changes and execute it on controller
  switch: (e) ->
    val = $(e.target).prop('checked')
    key = $(e.target).closest('.menu-item').data('key')
    return if !key
    worker = App.TaskManager.worker(key)
    return if !worker
    worker.switch(val)

  renderPersonal: =>
    @recentViewNavbarItemsRebuild()
    items = @getItems(navbar: @Config.get('NavBarRight'))

    # get open tabs to repopen on rerender
    openTab = {}
    @$('.open').children('a').each( (i,d) ->
      href = $(d).attr('href')
      openTab[href] = true
    )

    @$('.navbar-items-personal').html App.view('navigation/personal')(
      items:   items
      openTab: openTab
    )

    # only start avatar widget on existing session
    if App.Session.get('id')
      new App.WidgetAvatar(
        el:        @$('.js-avatar')
        object_id: App.Session.get('id')
        type:      'personal'
      )

  renderResult: (result = []) =>

    # remove result if not result exists
    if _.isEmpty(result)
      @searchContainer.removeClass('open')
      @globalSearch.close()
      @searchResult.html('')
      return

    # build markup
    html = App.view('navigation/result')(
      result: result
    )
    @searchResult.html(html)

    # show result list
    @searchContainer.addClass('open')

    # start ticket popups
    @ticketPopups()

    # start user popups
    @userPopups()

    # start oorganization popups
    @organizationPopups()

  render: ->

    user = App.Session.get()
    @html App.view('navigation')(
      user: user
    )

    @taskbar = new App.TaskbarWidget( el: @$('.tasks') )

    # renderMenu
    @renderMenu()

    # renderPersonal
    @renderPersonal()

    if @notificationWidget
      @notificationWidget.remove()
    @notificationWidget = new App.OnlineNotificationWidget()
    $('#app').append @notificationWidget.el

  searchFocus: (e) =>
    @query = '' # reset query cache
    @searchContainer.addClass('focused')
    @anyPopoversDestroy()
    @search()

  searchBlur: (e) =>

    # delay to be able to click x
    update = =>
      query = @searchInput.val().trim()
      if !query
        @emptyAndClose()
        return
      @searchContainer.removeClass('focused')

    @delay(update, 100, 'removeFocused')

  listNavigate: (e) =>
    if e.keyCode is 27 # close on esc
      @emptyAndClose()
      @searchInput.blur()
      return
    else if e.keyCode is 38 # up
      @nudge(e, -1)
      return
    else if e.keyCode is 40 # down
      @nudge(e, 1)
      return
    else if e.keyCode is 13 # enter
      if @$('.global-search-menu .js-details-link.is-hover').get(0)
        @openExtendedSearch()
        return
      href = @$('.global-search-result .nav-tab.is-hover').attr('href')
      return if !href
      @navigate(href)
      @emptyAndClose()
      @searchInput.blur()
      return

    # on other keys, show result
    @throttledSearch()

  nudge: (e, position) =>

    return if !@searchContainer.hasClass('open')

    # get current
    current = @searchResult.find('.nav-tab.is-hover')
    if !current.get(0)

      # if down, select detail search of first result
      if position is 1
        if !@searchDetails.hasClass('is-hover')
          @searchDetails.addClass('is-hover')
          return

        @searchDetails.removeClass('is-hover')
        @searchResult.find('.nav-tab').first().addClass('is-hover').popover('show')
        return

    if position is 1
      next = current.closest('li').nextAll('li').not('.divider').first().find('.nav-tab')
      if next.get(0)
        current.removeClass('is-hover').popover('hide')
        next.addClass('is-hover').popover('show')
    else
      prev = current.closest('li').prevAll('li').not('.divider').first().find('.nav-tab')
      if prev.get(0)
        current.removeClass('is-hover').popover('hide')
        prev.addClass('is-hover').popover('show')
      else
        current.removeClass('is-hover').popover('hide')
        @searchDetails.addClass('is-hover')

    if next
      @scrollToIfNeeded(next, true)
    if prev
      @scrollToIfNeeded(prev, false)

  emptyAndClose: =>
    @searchInput.val('')
    @searchContainer.removeClass('filled').removeClass('open').removeClass('focused')
    @globalSearch.close()

    # remove not needed popovers
    @delay(@anyPopoversDestroy, 100, 'removePopovers')

  andClose: =>
    @searchInput.blur()
    @searchContainer.removeClass('open')
    @globalSearch.close()
    @delay(@anyPopoversDestroy, 100, 'removePopovers')

  search: =>
    query = @searchInput.val().trim()
    return if !query
    return if query is @query
    @query = query
    @searchContainer.toggleClass('filled', !!@query)
    @globalSearch.search(query: @query)

  getItems: (data) ->
    navbar =  _.values(data.navbar)

    level1 = []
    dropdown = {}

    user = undefined
    if App.Session.get('id')
      user = App.User.find(App.Session.get('id'))

    for item in navbar
      if typeof item.callback is 'function'
        data = item.callback() || {}
        for key, value of data
          item[key] = value
      if !item.parent
        match = true
        if item.permission
          match = false
          for permissionName in item.permission
            if !match && user && user.permission(permissionName)
              match = true
        if match
          level1.push item

    for item in navbar
      if item.parent && !dropdown[ item.parent ]
        dropdown[ item.parent ] = []

        # find all childs and order
        for itemSub in navbar
          if itemSub.parent is item.parent
            match = true
            if itemSub.permission
              match = false
              for permissionName in itemSub.permission
                if !match && user && user.permission(permissionName)
                  match = true
            if match
              dropdown[ item.parent ].push itemSub

        # find parent
        for itemLevel1 in level1
          if itemLevel1.target is item.parent
            sub = @getOrder(dropdown[ item.parent ])
            itemLevel1.child = sub

    # clean up, only show navbar items with existing childrens
    clean_list = []
    for item in level1
      if !item.child || item.child && !_.isEmpty(item.child)
        clean_list.push item
    nav = @getOrder(clean_list)
    return nav

  getOrder: (data) ->
    newlist = {}
    for item in data
      # check if same prio already exists
      @addPrioCount newlist, item

      newlist[ item['prio'] ] = item;

    # get keys for sort order
    keys = _.keys(newlist)
    inorder = keys.sort(@sortit)

    # create new array with prio sort order
    inordervalue = []
    for num in inorder
      inordervalue.push newlist[ num ]

    # add differ to after recent viewed item
    found = false
    for value in inordervalue
      if value.type is 'recentViewed'
        found = true
      if found && value.type isnt 'recentViewed'
        value.divider = true
        found = false

    return inordervalue

  sortit: (a,b) ->
    return(a-b)

  addPrioCount: (newlist, item) ->
    if newlist[ item['prio'] ]
      item['prio']++
      if newlist[ item['prio'] ]
        @addPrioCount newlist, item

  update: (params) =>
    url = params
    if _.isObject(params)
      url = params.url
      type = params.type
    if type is 'menu'
      @$('.js-menu .is-active, .js-details-link.is-active').removeClass('is-active')
    else
      @$('.is-active').removeClass('is-active')
    return if !url || url is '#'
    @$("[href=\"#{url}\"]").addClass('is-active')

  recentViewNavbarItemsRebuild: =>

    # remove old views
    NavBarRight = @Config.get('NavBarRight') || {}
    for key of NavBarRight
      if NavBarRight[key].parent is '#current_user'
        part = key.split '::'
        if part[0] is 'RecendViewed'
          delete NavBarRight[key]

    if !@Session.get()
      @Config.set('NavBarRight', NavBarRight)
      return

    # add new views
    items = App.RecentView.search(sortBy: 'created_at', order: 'DESC')
    items = @prepareForObjectList(items)
    prio = 80
    for item in items
      divider   = false
      navheader = false
      if prio is 80
        divider   = true
        navheader = 'Recently viewed'

      prio++
      NavBarRight['RecendViewed::' + item.o_id + item.object + '-' + prio ] = {
        prio:      prio
        parent:    '#current_user'
        name:      App.i18n.translateInline(item.object) + ' (' + item.title + ')'
        target:    item.link
        divider:   divider
        navheader: navheader
        type:      'recentViewed'
      }

    @Config.set('NavBarRight', NavBarRight)

  fetchRecentView: =>
    load = (data) =>
      App.RecentView.refresh(data.stream, clear: true)
      @renderPersonal()
    App.RecentView.fetchFull(load)

  toggleNotifications: (e) ->
    e.stopPropagation()
    @notificationWidget.toggle()

  openExtendedSearch: (e) ->
    if e
      e.preventDefault()
    query = @searchInput.val()
    @searchInput.val('').blur()
    if query
      @navigate("#search/#{encodeURIComponent(query)}")
      return
    @navigate('#search')

App.Config.set('navigation', App.Navigation, 'Navigations')

class App.Navigation extends App.ControllerWidgetPermanent
  className: 'navigation vertical'

  constructor: ->
    super
    @render()

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
    @bind 'navupdate', =>
      @update(arguments[0])

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
          -> App.Event.trigger('bell', 'off' )
          3000
        )
      else
        @$('.bell').removeClass('show')

  renderMenu: =>
    items = @getItems( navbar: @Config.get( 'NavBar' ) )

    # apply counter and switch info from persistant controllers (if exists)
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
          if worker.featureActive
            if worker.featureActive()
              shown = true
            else
              shown = false
      if shown
        itemsNew.push item
    items = itemsNew

    # get open tabs to repopen on rerender
    open_tab = {}
    @$('.open').children('a').each( (i,d) ->
      href = $(d).attr('href')
      open_tab[href] = true
    )

    # get active tabs to reactivate on rerender
    active_tab = {}
    @$('.is-active').each( (i,d) ->
      href = $(d).attr('href')
      active_tab[href] = true
    )

    # render menu
    @$('.js-menu').html App.view('navigation/menu')(
      items:      items
      open_tab:   open_tab
      active_tab: active_tab
    )

    # bind on switch changes and execute it on controller
    @$('.js-menu .js-switch input').bind('change', (e) ->
      val = $(e.target).prop('checked')
      key = $(e.target).closest('.menu-item').data('key')
      return if !key
      worker = App.TaskManager.worker(key)
      return if !worker
      worker.switch(val)
    )

  renderPersonal: =>
    @recentViewNavbarItemsRebuild()
    items = @getItems( navbar: @Config.get( 'NavBarRight' ) )

    # get open tabs to repopen on rerender
    open_tab = {}
    @$('.open').children('a').each( (i,d) ->
      href = $(d).attr('href')
      open_tab[href] = true
    )

    # get active tabs to reactivate on rerender
    active_tab = {}
    @$('.active').children('a').each( (i,d) ->
      href = $(d).attr('href')
      active_tab[href] = true
    )

    @$('.navbar-items-personal').html App.view('navigation/personal')(
      items:      items
      open_tab:   open_tab
      active_tab: active_tab
    )

    # only start avatar widget on existing session
    if App.Session.get('id')
      new App.WidgetAvatar(
        el:       @$('.js-avatar')
        user_id:  App.Session.get('id')
        type:     'personal'
      )

  renderResult: (result = []) =>
    el = @$('#global-search-result')

    # remove result if not result exists
    if _.isEmpty(result)
      @$('.search').removeClass('open')
      el.html('')
      return

    # build markup
    html = App.view('navigation/result')(
      result: result
    )
    el.html(html)

    # show result list
    @$('.search').addClass('open')

    # start ticket popups
    @ticketPopups()

    # start user popups
    @userPopups()

    # start oorganization popups
    @organizationPopups()

  render: ->

    # reset result cache
    @searchResultCache = {}

    user = App.Session.get()
    @html App.view('navigation')(
      user: user
    )

    @taskbar = new App.TaskbarWidget( el: @$('.tasks') )

    # renderMenu
    @renderMenu()

    # renderPersonal
    @renderPersonal()

    # observer search box
    @$('#global-search').bind('focusout', (e) =>
      # delay to be able to click x
      update = =>
        @$('.search').removeClass('focused')
      @delay(update, 100, 'removeFocused')
    )
    @$('#global-search').bind('focusin', (e) =>
      @query = '' # reset query cache
      @$('.search').addClass('focused')
      @anyPopoversDestroy()
      @searchFunction(0)
    )
    @$('form.search').on('submit', (e) ->
      e.preventDefault()
    )
    @$('#global-search').on('keydown', @navigate)

    # bind to empty search
    @$('.empty-search').on('click', =>
      @emptyAndClose()
    )

    new App.OnlineNotificationWidget(
      el: @el
    )

  navigate: (e) =>
    if e.keyCode is 27 # close on esc
      @emptyAndClose()
      return
    else if e.keyCode is 38 # up
      @nudge(e, -1)
      return
    else if e.keyCode is 40 # down
      @nudge(e, 1)
      return
    else if e.keyCode is 13 # enter
      href = @$('#global-search-result .nav-tab.is-active').attr('href')
      @locationExecute(href)
      @emptyAndClose()
      return

    # on other keys, show result
    @searchFunction(200)

  nudge: (e, position) =>

    # get current
    navigationResult = @$('#global-search-result')
    current = navigationResult.find('.nav-tab.is-active')
    if !current.get(0)
      navigationResult.find('.nav-tab').first().addClass('is-active')
      return

    if position is 1
      next = current.closest('li').nextAll('li').not('.divider').first().find('.nav-tab')
      if next.get(0)
        current.removeClass('is-active').popover('hide')
        next.addClass('is-active').popover('show')
    else
      prev = current.closest('li').prevAll('li').not('.divider').first().find('.nav-tab')
      if prev.get(0)
        current.removeClass('is-active').popover('hide')
        prev.addClass('is-active').popover('show')

  emptyAndClose: =>
    @$('#global-search').val('').blur()
    @$('.search').removeClass('filled').removeClass('open')

    # remove not needed popovers
    @delay(@anyPopoversDestroy, 100, 'removePopovers')

  andClose: =>
    @$('#global-search').blur()
    @$('.search').removeClass('open')
    @delay(@anyPopoversDestroy, 100, 'removePopovers')

  searchFunction: (delay) =>

    search = =>
      query = @$('#global-search').val().trim()
      return if !query
      return if query is @query
      @query = query
      @$('.search').toggleClass('filled', !!@query)

      # use cache for search result
      if @searchResultCache[@query]
        @renderResult(@searchResultCache[@query].result)
        currentTime = new Date
        return if @searchResultCache[@query].time > currentTime.setSeconds(currentTime.getSeconds() - 20)

      App.Ajax.request(
        id:    'search'
        type:  'GET'
        url:   @apiPath + '/search'
        data:
          query: @query
        processData: true,
        success: (data, status, xhr) =>
          App.Collection.loadAssets(data.assets)
          result = {}
          for item in data.result
            if App[item.type] && App[item.type].find
              if !result[item.type]
                result[item.type] = []
              item_object = App[item.type].find(item.id)
              if item_object.searchResultAttributes
                item_object_search_attributes = item_object.searchResultAttributes()
                result[item.type].push item_object_search_attributes
              else
                @log 'error', "No such model #{item.type.toLocaleLowerCase()}.searchResultAttributes()"
            else
              @log 'error', "No such model App.#{item.type}"

          diff = false
          if @searchResultCache[@query]
            diff = difference(@searchResultCache[@query].resultRaw, data.result)

          # cache search result
          @searchResultCache[@query] =
            result: result
            resultRaw: data.result
            time: new Date

          # if result hasn't changed, do not rerender
          return if diff isnt false && _.isEmpty(diff)

          @renderResult(result)

          @$('#global-search-result').on('click', 'a', =>
            @andClose()
          )
      )
    @delay(search, 200, 'search')

  getItems: (data) ->
    navbar =  _.values(data.navbar)

    level1 = []
    dropdown = {}

    roles = App.Session.get( 'roles' )

    for item in navbar
      if typeof item.callback is 'function'
        data = item.callback() || {}
        for key, value of data
          item[key] = value
      if !item.parent
        match = 0
        if !item.role
          match = 1
        if !roles && item.role
          match = _.include( item.role, 'Anybody' )
        if roles
          for role in roles
            if !match
              match = _.include( item.role, role.name )

        if match
          level1.push item

    for item in navbar
      if item.parent && !dropdown[ item.parent ]
        dropdown[ item.parent ] = []

        # find all childs and order
        for itemSub in navbar
          if itemSub.parent is item.parent
            match = 0
            if !itemSub.role
              match = 1
            if !roles
              match = _.include( itemSub.role, 'Anybody' )
            if roles
              for role in roles
                if !match
                  match = _.include( itemSub.role, role.name )

            if match
              dropdown[ item.parent ].push itemSub

        # find parent
        for itemLevel1 in level1
          if itemLevel1.target is item.parent
            sub = @getOrder( dropdown[ item.parent ] )
            itemLevel1.child = sub

    # clean up, only show navbar items with existing childrens
    clean_list = []
    for item in level1
      if !item.child || item.child && !_.isEmpty( item.child )
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

  update: (url) =>
    @$('.is-active').removeClass('is-active')
    return if !url || url is '#'
    @$("[href=\"#{url}\"]").addClass('is-active')

  recentViewNavbarItemsRebuild: =>

    # remove old views
    NavBarRight = @Config.get( 'NavBarRight' ) || {}
    for key of NavBarRight
      if NavBarRight[key].parent is '#current_user'
        part = key.split '::'
        if part[0] is 'RecendViewed'
          delete NavBarRight[key]

    if !@Session.get()
      @Config.set( 'NavBarRight', NavBarRight )
      return

    # add new views
    items = App.RecentView.search(sortBy: 'created_at', order: 'DESC' )
    items = @prepareForObjectList(items)
    prio = 80
    for item in items
      divider   = false
      navheader = false
      if prio is 80
        divider   = true
        navheader = 'Recent Viewed'

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

    @Config.set( 'NavBarRight', NavBarRight )

  fetchRecentView: =>
    load = (items) =>
      App.RecentView.refresh( items, { clear: true } )
      @renderPersonal()
    App.RecentView.fetchFull(load)

App.Config.set( 'navigation', App.Navigation, 'Navigations' )

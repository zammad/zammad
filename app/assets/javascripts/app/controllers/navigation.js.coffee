class App.Navigation extends App.Controller
  className: 'navigation vertical'

  events:
    'click .empty-search': 'emptySearch'

  constructor: ->
    super
    @render()

    # rerender view
    @bind 'ui:rerender', (data) =>
      @renderMenu()
      @renderPersonal()

    # update selected item
    @bind 'navupdate', (data) =>
      @update( arguments[0] )

    # rebuild nav bar with given user data
    @bind 'auth', (user) =>
      @log 'Navigation', 'notice', 'navbar rebuild', user

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
        @el.find('.bell').addClass('show')
        App.Audio.play( 'https://www.sounddogs.com/previews/2193/mp3/219024_SOUNDDOGS__be.mp3' )
        @delay(
          -> App.Event.trigger('bell', 'off' )
          3000
        )
      else
        @el.find('.bell').removeClass('show')

  renderMenu: =>
    items = @getItems( navbar: @Config.get( 'NavBar' ) )

    # get open tabs to repopen on rerender
    open_tab = {}
    @el.find('.open').children('a').each( (i,d) =>
      href = $(d).attr('href')
      open_tab[href] = true
    )

    # get active tabs to reactivate on rerender
    active_tab = {}
    @el.find('.active').children('a').each( (i,d) =>
      href = $(d).attr('href')
      active_tab[href] = true
    )
    @el.find('.main-navigation').html App.view('navigation/menu')(
      items:      items
      open_tab:   open_tab
      active_tab: active_tab
    )

  renderPersonal: =>
    @recentViewNavbarItemsRebuild()
    items = @getItems( navbar: @Config.get( 'NavBarRight' ) )

    # get open tabs to repopen on rerender
    open_tab = {}
    @el.find('.open').children('a').each( (i,d) =>
      href = $(d).attr('href')
      open_tab[href] = true
    )

    # get active tabs to reactivate on rerender
    active_tab = {}
    @el.find('.active').children('a').each( (i,d) =>
      href = $(d).attr('href')
      active_tab[href] = true
    )

    @el.find('.navbar-items-personal').html App.view('navigation/personal')(
      items:      items
      open_tab:   open_tab
      active_tab: active_tab
    )

  renderResult: (result = []) =>
    el = @el.find('#global-search-result')

    # destroy existing popovers
    @ticketPopupsDestroy()
    @userPopupsDestroy()
    @organizationPopupsDestroy()

    # remove result if not result exists
    if _.isEmpty( result )
      @el.find('.search').removeClass('open')
      el.html( '' )
      return

    # build markup
    html = App.view('navigation/result')(
      result: result
    )
    el.html( html )

    # show result list
    @el.find('.search').addClass('open')

    # start ticket popups
    @ticketPopups()

    # start user popups
    @userPopups()

    # start oorganization popups
    @organizationPopups()

  render: () ->

    # remember old search query
    search = @el.find('#global-search').val()

    user   = App.Session.get()
    @html App.view('navigation')(
      user:         user
      search:       search
    )

    # renderMenu
    @renderMenu()

    # renderPersonal
    @renderPersonal()

    # set focus to search box
    if @searchFocus
      @searchFocusSet = true
      App.ClipBoard.setPosition( 'global-search', search.length )

    else
      @searchFocusSet = false

    searchFunction = =>
      App.Ajax.request(
        id:    'search'
        type:  'GET'
        url:   @apiPath + '/search'
        data:
          term: @term
        processData: true,
        success: (data, status, xhr) =>

          # load assets
          App.Collection.loadAssets( data.assets )

          result = data.result
          for area in result
            if area.name is 'Ticket'
              area.result = []
              for id in area.ids
                ticket = App.Ticket.find( id )
                ticket.humanTime = @humanTime(ticket.created_at)
                data =
                  display:    "##{ticket.number} - #{ticket.title}"
                  createt_at: "#{ticket.created_at}"
                  humanTime:  "#{ticket.humanTime}"
                  id:         ticket.id
                  class:      "task level-1 ticket-popover"
                  url:        ticket.uiUrl()
                  iconClass:  "priority"
                area.result.push data
            else if area.name is 'User'
              area.result = []
              for id in area.ids
                user = App.User.find( id )
                data =
                  display:    "#{user.displayName()}"
                  id:         user.id
                  class:      "user user-popover"
                  url:        user.uiUrl()
                  iconClass:  "user"
                area.result.push data
            else if area.name is 'Organization'
              area.result = []
              for id in area.ids
                organization = App.Organization.find( id )
                data =
                  display:    "#{organization.displayName()}"
                  id:         organization.id
                  class:      "organisation organization-popover"
                  url:        organization.uiUrl()
                  iconClass:  "organisation"
                area.result.push data

          @renderResult(result)
      )

    # observer search box
    @el.find('#global-search').bind( 'focusin', (e) =>

      # remember to set search box
      @searchFocus = true

      @el.find('.search').addClass('focused')

      # check if search is needed
      @term = @el.find('#global-search').val()
      return if @searchFocusSet
      return if !@term
      @delay( searchFunction, 200, 'search' )
    )

    # remove search result
    @el.find('#global-search').bind( 'focusout', (e) =>
      @el.find('.search').removeClass('focused')

      @delay(
        =>
          @searchFocus = false
          @renderResult()
        320
      )
    )

    # prevent submit of search box
    @el.find('form.search').bind( 'submit', (e) =>
      e.preventDefault()
    )

    # start search
    @el.find('#global-search').bind( 'keyup', (e) =>
      @term = @el.find('#global-search').val()

      @el.find('.search').toggleClass('filled', !!@term)

      return if !@term
      return if @term is search
      @delay( searchFunction, 220, 'search' )
    )

    new App.OnlineNotificationWidget(
      el: @el
    )

    @taskbar = new App.TaskbarWidget( el: @el.find('.tasks') )

  emptySearch: (event) =>
    @el.find('#global-search').val("")
    @el.find('.search').removeClass('filled')

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
    @el.find('li').removeClass('active')
    @el.find("[href=\"#{url}\"]").parents('li').addClass('active')

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

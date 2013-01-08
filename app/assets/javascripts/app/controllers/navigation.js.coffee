$ = jQuery.sub()

class App.Navigation extends App.Controller
  constructor: ->
    super
    @render()

    # update selected item
    App.Event.bind 'navupdate', (data) =>
      @update(arguments[0])

    # rebuild nav bar with given user data
    App.Event.bind 'ajax:auth', (user) =>
      @log 'Navigation', 'notice', 'navbar rebuild', user

      if !_.isEmpty( user )
        cache = App.Store.get( 'navupdate_ticket_overview' )
        @ticket_overview_build( cache ) if cache

      if !_.isEmpty( user )
        cache = App.Store.get( 'update_recent_viewed' )
        @recent_viewed_build( cache ) if cache

      @render(user)

    # rebuild ticket overview data
    App.Event.bind 'navupdate_ticket_overview', (data) =>
      @ticket_overview_build(data)
      @render( App.Session.all() )

    # rebuild recent viewd data
    App.Event.bind 'update_recent_viewed', (data) =>
      @recent_viewed_build(data)
      @render( App.Session.all() )

  render: (user) ->
    nav_left  = @getItems( navbar: @Config.get( 'NavBar' ) )
    nav_right = @getItems( navbar: @Config.get( 'NavBarRight' ) )

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

    search = @el.find('#global-search').val()
    @html App.view('navigation')(
      navbar_left:  nav_left
      navbar_right: nav_right
      open_tab:     open_tab
      active_tab:   active_tab
      user:         user
      tickets:      @tickets || []
      search:       search
    )

    # set focus to search box
    if @searchFocus
      @searchFocusSet = true
      App.ClipBoard.setPosition( 'global-search', search.length )

    else
      @searchFocusSet = false

    searchFunction = =>
      App.Com.ajax(
        id:    'ticket_search'
        type:  'GET'
        url:   'api/tickets/search'
        data:
          term: @term
        processData: true,
        success: (data, status, xhr) =>

          # load user collection
          if data.users
            App.Collection.load( type: 'User', data: data.users )

          # load ticket collection
          if data.tickets
            App.Collection.load( type: 'Ticket', data: data.tickets )

            @tickets = []

            for ticket_raw in data.tickets
              ticket = App.Collection.find( 'Ticket', ticket_raw.id )

              # set human time
              ticket.humanTime = @humanTime(ticket.created_at)

              @tickets.push ticket
            @render(user)
      )

    # observer search box
    @el.find('#global-search').bind( 'focusin', (e) =>

      # remember to set search box
      @searchFocus = true

      # check if search is needed
      @term = @el.find('#global-search').val()
      return if @searchFocusSet
      return if !@term
      @delay( searchFunction, 200, 'search' )
    )

    # remove search result
    @el.find('#global-search').bind( 'focusout', (e) =>
      @delay(
        =>
          @searchFocus = false
          @tickets = []
          @render(user)
        320
      )
    )

    # prevent submit of search box
    @el.find('#global-search').parent().bind( 'submit', (e) =>
      e.preventDefault()
    )

    # start search
    @el.find('#global-search').bind( 'keyup', (e) =>
      @term = @el.find('#global-search').val()
      return if !@term
      return if @term is search
      @delay( searchFunction, 220, 'search' )
    )

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

    nav = @getOrder(level1)
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

  ticket_overview_build: (data) =>

    App.Store.write( 'navupdate_ticket_overview', data )

    # remove old views
    NavBar = @Config.get( 'NavBar' ) || {}
    for key of NavBar
      if NavBar[key].parent is '#ticket_view'
        delete NavBar[key]

    # add new views
    for item in data
      NavBar['TicketOverview' + item.url] = {
        prio:   item.prio,
        parent: '#ticket_view',
        name:   item.name,
        count:  item.count,
        target: '#ticket_view/' + item.url,
#        role:   ['Agent', 'Customer'],
      }

    @Config.set( 'NavBar', NavBar )

  recent_viewed_build: (data) =>

    App.Store.write( 'update_recent_viewed', data )

    items = data.recent_viewed

    # load user collection
    App.Collection.load( type: 'User', data: data.users )

    # load ticket collection
    App.Collection.load( type: 'Ticket', data: data.tickets )

    # remove old views
    NavBarRight = @Config.get( 'NavBarRight' ) || {}
    for key of NavBarRight
      if NavBarRight[key].parent is '#current_user'
        part = key.split '::'
        if part[0] is 'RecendViewed'
          delete NavBarRight[key]

    # add new views
    prio = 8000
    for item in items
      divider   = false
      navheader = false
      if prio is 8000
        divider   = true
        navheader = 'Recent Viewed'
      ticket = App.Collection.find( 'Ticket', item.o_id )
      prio++
      NavBarRight['RecendViewed::' + ticket.id + '-' + prio ] = {
        prio:      prio,
        parent:    '#current_user',
        name:      item.history_object + ' (' + ticket.title + ')',
        target:    '#ticket/zoom/' + ticket.id,
        divider:   divider,
        navheader: navheader
      }

    @Config.set( 'NavBarRight', NavBarRight )

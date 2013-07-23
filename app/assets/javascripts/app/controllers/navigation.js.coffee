class App.Navigation extends App.Controller
  constructor: ->
    super
    @render()

    # rerender view
    App.Event.bind 'ui:rerender', (data) =>
      @render()

    # update selected item
    App.Event.bind 'navupdate', (data) =>
      @update( arguments[0] )

    # rebuild nav bar with given user data
    App.Event.bind 'auth', (user) =>
      @log 'Navigation', 'notice', 'navbar rebuild', user

      if !_.isEmpty( user )
        cache = App.Store.get( 'navupdate_ticket_overview' )
        @ticket_overview_build( cache ) if cache

      if !_.isEmpty( user )
        cache = App.Store.get( 'update_recent_viewed' )
        @recent_viewed_build( cache ) if cache

      @render()

    # rebuild ticket overview data
    App.Event.bind 'navupdate_ticket_overview', (data) =>
      @ticket_overview_build(data)
      @render()

    # rebuild recent viewed data
    App.Event.bind 'update_recent_viewed', (data) =>
      @recent_viewed_build(data)
      @render()

  render: () ->
    user      = App.Session.all()
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
      result:       @result || []
      search:       search
    )

    # start ticket popups
    @ticketPopups('right')

    # start user popups
    @userPopups('right')

    # start oorganization popups
    @organizationPopups('right')

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
        url:   'api/search'
        data:
          term: @term
        processData: true,
        success: (data, status, xhr) =>

          # load user collection
          if data.load.users
            App.Collection.load( type: 'User', data: data.load.users )

          # load user collection
          if data.load.organizations
            for organization_id, organization of data.load.organizations
              if organization.user_ids
                organization.users = []
                for user_id in organization.user_ids
                  user = App.User.find( user_id )
                  organization.users.push user
            App.Collection.load( type: 'Organization', data: data.load.organizations )


          # load ticket collection
          if data.load.tickets
            App.Collection.load( type: 'Ticket', data: data.load.tickets )

          @result = data.result
          for area in @result
            if area.name is 'Ticket'
              area.result = []
              for id in area.ids
                ticket = App.Ticket.find( id )
                ticket.humanTime = @humanTime(ticket.created_at)
                data =
                  display:  "##{ticket.number} - #{ticket.title} - #{ticket.humanTime}"
                  id:       ticket.id
                  class:    "ticket-data"
                  url:      "#ticket/zoom/#{ticket.id}"
                area.result.push data
            else if area.name is 'User'
              area.result = []
              for id in area.ids
                user = App.User.find( id )
                data =
                  display:  "#{user.displayName()}"
                  id:       user.id
                  class:    "user-data"
                  url:      "#users/#{user.id}"
                area.result.push data
            else if area.name is 'Organization'
              area.result = []
              for id in area.ids
                organization = App.Organization.find( id )
                data =
                  display:  "#{organization.displayName()}"
                  id:       organization.id
                  class:    "organization-data"
                  url:      "#organizations/#{ticket.id}"
                area.result.push data

          if @result
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
          @result = []
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
      NavBar['TicketOverview' + item.link] = {
        prio:   item.prio,
        parent: '#ticket_view',
        name:   item.name,
        count:  item.count,
        target: '#ticket_view/' + item.link,
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
      ticket = App.Ticket.find( item.o_id )
      prio++
      NavBarRight['RecendViewed::' + ticket.id + '-' + prio ] = {
        prio:      prio,
        parent:    '#current_user',
        name:      item.recent_view_object + ' (' + ticket.title + ')',
        target:    '#ticket/zoom/' + ticket.id,
        divider:   divider,
        navheader: navheader
      }

    @Config.set( 'NavBarRight', NavBarRight )

App.Config.set( 'navigation', App.Navigation, 'Navigations' )

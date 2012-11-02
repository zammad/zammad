$ = jQuery.sub()

class App.Navigation extends App.Controller
  constructor: ->
    super
    @log 'nav...'
    @render()

    # update selected item
    App.Event.bind 'navupdate', (data) =>
      @update(arguments[0])

    # rebuild nav bar with given user data
    App.Event.bind 'ajax:auth', (user) =>
      @log 'navbar rebuild', user

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
      @render( window.Session )

    # rebuild recent viewd data
    App.Event.bind 'update_recent_viewed', (data) =>
      @recent_viewed_build(data)
      @render( window.Session )

  render: (user) ->
    nav_left  = @getItems( navbar: Config.NavBar )
    nav_right = @getItems( navbar: Config.NavBarRight )

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
    
    @html App.view('navigation')(
      navbar_left:  nav_left,
      navbar_right: nav_right,
      open_tab:     open_tab,
      active_tab:   active_tab,
      user:         user,
    )

  getItems: (data) ->
    navbar =  _.values(data.navbar)
    
    level1 = []
    dropdown = {}

    for item in navbar
      if typeof item.callback is 'function'
        data = item.callback() || {}
        for key, value of data
          item[key] = value
      if !item.parent
        match = 0
        if !window.Session['roles']
          match = _.include(item.role, 'Anybody')
        if window.Session['roles']
          window.Session['roles'].forEach( (role) =>
            if !match
              match = _.include(item.role, role.name)
          )
          
        if match
          level1.push item
            
    for item in navbar
      if item.parent && !dropdown[ item.parent ]
        dropdown[ item.parent ] = []

        # find all childs and order
        for itemSub in navbar
          if itemSub.parent is item.parent
            match = 0
            if !window.Session['roles']
              match = _.include(itemSub.role, 'Anybody')
            if window.Session['roles']
              window.Session['roles'].forEach( (role) =>
                if !match
                  match = _.include(itemSub.role, role.name)
              )
              
            if match
              dropdown[ item.parent ].push itemSub

        # find parent
        for itemLevel1 in level1
          if itemLevel1.target is item.parent
            sub = @getOrder(dropdown[ item.parent ])
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
    for key of Config.NavBar
      if Config.NavBar[key].parent is '#ticket_view'
        delete Config.NavBar[key]

    # add new views
    for item in data
      Config.NavBar['TicketOverview' + item.url] = {
        prio:   item.prio,
        parent: '#ticket_view',
        name:   item.name,
        count:  item.count,
        target: '#ticket_view/' + item.url,
        role:   ['Agent'],
      }

  recent_viewed_build: (data) =>

    App.Store.write( 'update_recent_viewed', data )

    items = data.recent_viewed

    # load user collection
    App.Collection.load( type: 'User', data: data.users )

    # load ticket collection
    App.Collection.load( type: 'Ticket', data: data.tickets )

    # remove old views
    for key of Config.NavBarRight
      if Config.NavBarRight[key].parent is '#current_user'
        part = key.split '::'
        if part[0] is 'RecendViewed'
          delete Config.NavBarRight[key]

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
      Config.NavBarRight['RecendViewed::' + ticket.id + '-' + prio ] = {
        prio:      prio,
        parent:    '#current_user',
        name:      item.history_object.name + ' (' + ticket.title + ')',
        target:    '#ticket/zoom/' + ticket.id,
        role:      ['Agent'],
        divider:   divider,
        navheader: navheader
      }

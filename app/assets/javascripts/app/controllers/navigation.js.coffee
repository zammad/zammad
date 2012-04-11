$ = jQuery.sub()

class App.Navigation extends Spine.Controller
  events:
    'focusin [data-type=edit]':     'edit_in'

  constructor: ->
    super
    @log 'nav...'
    @render()
    
    Spine.bind 'navupdate', (data) =>
      @update(arguments[0])
    
    Spine.bind 'navrebuild', (user) =>
      @log 'navbarrebuild', user
      @render(user)

    Spine.bind 'navupdate_remote', (user) =>
      @log 'navupdate_remote'
      @delay( @sync, 500 )
    
    # rerender if new overview data is there
    @delay( @sync, 800 )
    @delay( @sync, 2000 )
    
  render: (user) ->
#    @log 'nav render', Config.NavBar
#    @log '111', _.keys(Config.NavBar)
    navbar =  _.values(Config.NavBar)
    
    level1 = []
    dropdown = {}

    for item in navbar
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
    @html App.view('navigation')(
      navbar: nav,
      user: user,
    )

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
#    if url isnt '#'
    @el.find("[href=\"#{url}\"]").parents('li').addClass('active')
#      @el.find("[href*=\"#{url}\"]").parents('li').addClass('active')

  sync: =>
    
    @ticket_overview()

    # auto save
    every = (ms, cb) -> setInterval cb, ms

    # clear auto save
    clearInterval(@intervalID) if @intervalID
    
    # request new data
    @intervalID = every 30000, () =>
      @ticket_overview()
 
  # get data
  ticket_overview: =>

    # do no load and rerender if sub-menu is open
    open = @el.find('.open').val()
    if open isnt undefined
      return
    
    # do no load and rerender if user is not logged in
    if !window.Session['id']
      return

    @ajax = new App.Ajax
    @ajax.ajax(
      type:  'GET',
      url:   '/ticket_overviews',
      data:  {},
      processData: true,
      success: (data, status, xhr) =>

        # remove old views
        for key of Config.NavBar
          if Config.NavBar[key].parent is '#ticket/view'
            delete Config.NavBar[key]

        # add new views
        for item in data
          Config.NavBar['TicketOverview' + item.url] = {
            prio:   item.prio,
            parent: '#ticket/view',
            name:   item.name + ' (' + item.count + ')',
            target: '#ticket/view/' + item.url,
            role:   ['Agent'],
          }

        # rebuild navbar
        Spine.trigger 'navrebuild', window.Session
    )

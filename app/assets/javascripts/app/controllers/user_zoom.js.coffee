class App.UserZoom extends App.Controller
  elements:
    '.tabsSidebar'      : 'sidebar'

  constructor: (params) ->
    super

    # check authentication
    if !@authenticate()
      App.TaskManager.remove( @task_key )
      return

    @navupdate '#'

    App.User.full( @user_id, @render )

  meta: =>
    meta =
      url: @url()
      id:  @user_id

    if App.User.exists( @user_id )
      user = App.User.find( @user_id )

      meta.head       = user.displayName()
      meta.title      = user.displayName()
      meta.iconClass  = user.icon()
    meta

  url: =>
    '#user/zoom/' + @user_id

  activate: =>
    App.OnlineNotification.seen( 'User', @user_id )
    @navupdate '#'

  changed: =>
    formCurrent = @formParam( @el.find('.ticket-update') )
    diff = difference( @formDefault, formCurrent )
    return false if !diff || _.isEmpty( diff )
    return true

  render: (user) =>

    if !@doNotLog
      @doNotLog = 1
      @recentView( 'User', @user_id )

    @html App.view('user_zoom')(
      user:  user
    )

    new Overviews(
      el:   @el
      user: user
    )

    new App.UpdateTastbar(
      genericObject: user
    )

    new App.UpdateHeader(
      el:            @el
      genericObject: user
    )

    # start action controller
    showHistory = =>
      new App.UserHistory( user_id: user.id )

    actions = [
      {
        name:     'history'
        title:    'History'
        callback: showHistory
      }
    ]
    new App.ActionRow(
      el:    @el.find('.action')
      items: actions
    )

    new Sidebar(
      el:         @sidebar
      user:       user
      textModule: @textModule
    )

class Overviews extends App.Controller
  constructor: ->
    super

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = App.User.full( @user.id, @render, false, true )

  release: =>
    App.User.unsubscribe(@subscribeId)

  render: (user) =>

    plugins = {
      main: {
        my_assigned: {
          controller: App.DashboardTicketSearch,
          params: {
            name: 'Tickets of User'
            condition:
              'tickets.state_id': [ 1,2,3,4,6 ]
              'tickets.customer_id': user.id
            order:
              by:        'created_at'
              direction: 'DESC'
            view:
              d: [ 'number', 'title', 'state', 'priority', 'created_at' ]
              view_mode_default: 'd'
          },
        },
      },
    }
    if user.organization_id
      plugins.main.my_organization = {
        controller: App.DashboardTicketSearch,
        params: {
          name: 'Tickets of Organization'
          condition:
            'tickets.state_id': [ 1,2,3,4,6 ]
            'tickets.organization_id': user.organization_id
          order:
            by:        'created_at'
            direction: 'DESC'
          view:
            d: [ 'number', 'title', 'customer', 'state', 'priority', 'created_at' ]
            view_mode_default: 'd'
        },
      }

    for area, plugins of plugins
      for name, plugin of plugins
        target = area + '_' + name
        @el.find('.' + area + '-overviews').append('<div class="" id="' + target + '"></div>')
        if plugin.controller
          params = plugin.params || {}
          params.el = @el.find( '#' + target )
          new plugin.controller( params )

    dndOptions =
      handle:               'h2.can-move'
      placeholder:          'can-move-plcaeholder'
      tolerance:            'pointer'
      distance:             15
      opacity:              0.6
      forcePlaceholderSize: true

    @el.find( '#sortable' ).sortable( dndOptions )
    @el.find( '#sortable-sidebar' ).sortable( dndOptions )

class Sidebar extends App.Controller
  constructor: ->
    super

    # render ui
    @render()

  render: ->

    items = []

    showCustomer = (el) =>
      new App.WidgetUser(
        el:       el
        user_id:  @user.id
      )

    editCustomer = (e, el) =>
      new App.ControllerGenericEdit(
        id: @user.id
        genericObject: 'User'
        screen: 'edit'
        pageData:
          title: 'Users'
          object: 'User'
          objects: 'Users'
      )
    items.push {
      head: 'Customer'
      name: 'customer'
      icon: 'person'
      actions: [
        {
          name:  'Edit Customer'
          class: 'glyphicon glyphicon-edit'
          callback: editCustomer
        },
      ]
      callback: showCustomer
    }

    if @user.organization_id
      editOrganization = (e, el) =>
        new App.ControllerGenericEdit(
          id: @user.organization_id
          genericObject: 'Organization'
          pageData:
            title: 'Organizations'
            object: 'Organization'
            objects: 'Organizations'
        )
      showOrganization = (el) =>
        new App.WidgetOrganization(
          el:               el
          organization_id:  @user.organization_id
        )
      items.push {
        head: 'Organization'
        name: 'organization'
        icon: 'group'
        actions: [
          {
            name:     'Edit Organization'
            class:    'glyphicon glyphicon-edit'
            callback: editOrganization
          },
        ]
        callback: showOrganization
      }

    new App.Sidebar(
      el:     @el
      items:  items
    )

class Router extends App.ControllerPermanent
  constructor: (params) ->
    super

    # cleanup params
    clean_params =
      user_id:  params.user_id

    App.TaskManager.add( 'User-' + @user_id, 'UserZoom', clean_params )

App.Config.set( 'user/zoom/:user_id', Router, 'Routes' )

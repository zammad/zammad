class App.UserZoom extends App.Controller
  constructor: (params) ->
    super

    # check authentication
    return if !@authenticate()


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
    @navupdate '#'

  changed: =>
    formCurrent = @formParam( @el.find('.ticket-update') )
    diff = difference( @formDefault, formCurrent )
    return false if !diff || _.isEmpty( diff )
    return true

  render: (user) =>


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
    new ActionRow(
      el:   @el.find('.action')
      user: user
      ui:   @
    )

    new Widgets(
      el:   @el.find('.widgets')
      user: user
      ui:   @
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

class Widgets extends App.Controller
  constructor: ->
    super
    @render()

  render: ->

    new App.WidgetUser(
      el:      @el
      user_id: @user.id
    )

class ActionRow extends App.Controller
  events:
    'click [data-type=history]':  'history_dialog'
    'click [data-type=merge]':    'merge_dialog'

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('user_zoom/actions')()

  history_dialog: (e) ->
    e.preventDefault()
    new App.UserHistory( user_id: @user.id )

  merge_dialog: (e) ->
    e.preventDefault()
    new App.TicketMerge( ticket: @ticket, task_key: @ui.task_key )

  customer_dialog: (e) ->
    e.preventDefault()
    new App.TicketCustomer( ticket: @ticket, ui: @ui )


class Router extends App.ControllerPermanent
  constructor: (params) ->
    super

    # cleanup params
    clean_params =
      user_id:  params.user_id

    App.TaskManager.add( 'User-' + @user_id, 'UserZoom', clean_params )

App.Config.set( 'user/zoom/:user_id', Router, 'Routes' )

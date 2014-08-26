class App.OrganizationZoom extends App.Controller
  constructor: (params) ->
    super

    # check authentication
    return if !@authenticate()

    @navupdate '#'

    App.Organization.full( @organization_id, @render )

  meta: =>
    meta =
      url: @url()
      id:  @organization_id

    if App.Organization.exists( @organization_id )
      organization = App.Organization.find( @organization_id )

      meta.head       = organization.displayName()
      meta.title      = organization.displayName()
      meta.iconClass  = organization.icon()

    meta

  url: =>
    '#organization/zoom/' + @organization_id

  activate: =>
    App.OnlineNotification.seen( 'Organization', @organization_id )
    @navupdate '#'

  changed: =>
    formCurrent = @formParam( @el.find('.ticket-update') )
    diff = difference( @formDefault, formCurrent )
    return false if !diff || _.isEmpty( diff )
    return true

  render: (organization) =>

    if !@doNotLog
      @doNotLog = 1
      @recentView( 'Organization', @organization_id )

    @html App.view('organization_zoom')(
      organization:  organization
    )

    new Overviews(
      el:   @el
      organization: organization
    )

    new App.UpdateTastbar(
      genericObject: organization
    )

    new App.UpdateHeader(
      el:            @el
      genericObject: organization
    )

    # start action controller
    new ActionRow(
      el:           @el.find('.action')
      organization: organization
      ui:           @
    )

    new Widgets(
      el:           @el.find('.widgets')
      organization: organization
      ui:           @
    )

class Overviews extends App.Controller
  constructor: ->
    super

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = App.Organization.full( @organization.id, @render, false, true )

  release: =>
    App.Organization.unsubscribe(@subscribeId)

  render: (organization) =>

    plugins =
      main:
        my_organization:
          controller: App.DashboardTicketSearch,
          params:
            name: 'Tickets of Organization'
            condition:
              'tickets.state_id': [ 1,2,3,4,6 ]
              'tickets.organization_id': organization.id
            order:
              by:        'created_at'
              direction: 'DESC'
            view:
              d: [ 'number', 'title', 'customer', 'state', 'priority', 'created_at' ]
              view_mode_default: 'd'

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

    new App.WidgetOrganization(
      el:               @el
      organization_id:  @organization.id
    )

class ActionRow extends App.Controller
  events:
    'click [data-type=history]':  'history_dialog'

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('user_zoom/actions')()

  history_dialog: (e) ->
    e.preventDefault()
    new App.OrganizationHistory( organization_id: @organization.id )

class Router extends App.ControllerPermanent
  constructor: (params) ->
    super

    # cleanup params
    clean_params =
      organization_id:  params.organization_id

    App.TaskManager.add( 'Organization-' + @organization_id, 'OrganizationZoom', clean_params )

App.Config.set( 'organization/zoom/:organization_id', Router, 'Routes' )

class App.OrganizationZoom extends App.Controller
  constructor: (params) ->
    super

    # check authentication
    return if !@authenticate()

    @navupdate '#'

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = App.Organization.full( @organization_id, @render, false, true )

  release: =>
    App.Organization.unsubscribe(@subscribeId)

  meta: =>
    meta =
      url: @url()
      id:  @organization_id
    if @organization
      meta.head  = @organization.displayName()
      meta.title = @organization.displayName()
    meta

  url: =>
    '#organization/zoom/' + @organization_id

  activate: =>
    @navupdate '#'

  changed: =>
    formCurrent = @formParam( @el.find('.ticket-update') )
    diff = difference( @formDefault, formCurrent )
    return false if !diff || _.isEmpty( diff )
    return true

  render: (organization) =>
    @organization = organization

    # update taskbar with new meta data
    App.Event.trigger 'task:render'

    @html App.view('organization_zoom')(
      organization:  @organization
    )

    # start action controller
    new ActionRow(
      el:           @el.find('.action')
      organization: @organization
      ui:           @
    )

    new Widgets(
      el:           @el.find('.widgets')
      organization: @organization
      ui:           @
    )

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

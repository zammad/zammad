class App.OrganizationProfile extends App.Controller
  constructor: (params) ->
    super
    @init = params.init

    # fetch new data if needed
    App.Organization.full(@organization_id, @render)

  meta: =>
    meta =
      url: @url()
      id:  @organization_id

    if App.Organization.exists(@organization_id)
      organization = App.Organization.find(@organization_id)
      icon = organization.icon()

      if organization.active is false
        icon = 'inactive-' + icon

      meta.head       = organization.displayName()
      meta.title      = organization.displayName()
      meta.iconClass  = icon
      meta.active     = organization.active
    meta

  url: =>
    '#organization/profile/' + @organization_id

  show: =>
    App.OnlineNotification.seen('Organization', @organization_id)
    @navupdate(url: '#', type: 'menu')

  changed: ->
    false

  render: (organization) =>

    if !@doNotLog
      @doNotLog = 1
      @recentView('Organization', @organization_id)

    elLocal = $(App.view('organization_profile/index')(
      organization: organization
    ))

    new App.OrganizationProfileOrganization(
      object_id: organization.id
      el: elLocal.find('.js-name')
    )

    new App.OrganizationProfileObject(
      el:        elLocal.find('.js-object-container')
      object_id: organization.id
      taskKey:  @taskKey
    )

    new App.OrganizationProfileActionRow(
      el:        elLocal.find('.js-action')
      object_id: organization.id
    )

    new App.OrganizationProfileOrganizationAvatar(
      el:        elLocal.find('.js-organization-avatar')
      object_id: organization.id
    )

    new App.TicketStats(
      el:           elLocal.find('.js-ticket-stats')
      organization: organization
      init: @init
    )

    @html elLocal

    new App.UpdateTaskbar(
      genericObject: organization
    )

  setPosition: (position) =>
    @$('.profile').scrollTop(position)

  currentPosition: =>
    @$('.profile').scrollTop()

class Router extends App.ControllerPermanent
  @requiredPermission: ['ticket.agent', 'admin.organization']

  constructor: (params) ->
    super

    # check authentication
    @authenticateCheckRedirect()

    # cleanup params
    clean_params =
      organization_id:  params.organization_id

    App.TaskManager.execute(
      key:        "Organization-#{@organization_id}"
      controller: 'OrganizationProfile'
      params:     clean_params
      show:       true
    )

App.Config.set('organization/profile/:organization_id', Router, 'Routes')

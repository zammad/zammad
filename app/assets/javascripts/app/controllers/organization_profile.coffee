class App.OrganizationProfile extends App.Controller
  constructor: (params) ->
    super

    @authenticateCheckRedirect()

    # fetch new data if needed
    App.Organization.full(@organization_id, @render)

  meta: =>
    meta =
      url: @url()
      id:  @organization_id

    if App.Organization.exists(@organization_id)
      organization = App.Organization.find(@organization_id)

      meta.head       = organization.displayName()
      meta.title      = organization.displayName()
      meta.iconClass  = organization.icon()
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

    new Organization(
      object_id: organization.id
      el: elLocal.find('.js-name')
    )

    new Object(
      el:        elLocal.find('.js-object-container')
      object_id: organization.id
      taskKey:  @taskKey
    )

    new ActionRow(
      el:        elLocal.find('.js-action')
      object_id: organization.id
    )

    new App.TicketStats(
      el:           elLocal.find('.js-ticket-stats')
      organization: organization
    )

    @html elLocal

    new App.UpdateTastbar(
      genericObject: organization
    )

  setPosition: (position) =>
    @$('.profile').scrollTop(position)

  currentPosition: =>
    @$('.profile').scrollTop()

class ActionRow extends App.ControllerObserverActionRow
  model: 'Organization'
  observe:
    member_ids: true

  showHistory: (organization) =>
    new App.OrganizationHistory(
      organization_id: organization.id
      container: @el.closest('.content')
    )

  editOrganization: (organization) =>
    new App.ControllerGenericEdit(
      id: organization.id
      genericObject: 'Organization'
      screen: 'edit'
      pageData:
        title: 'Organizations'
        object: 'Organization'
        objects: 'Organizations'
      container: @el.closest('.content')
    )

  actions: =>
    actions = [
      {
        name:     'edit'
        title:    'Edit'
        callback: @editOrganization
      }
      {
        name:     'history'
        title:    'History'
        callback: @showHistory
      }
    ]

class Object extends App.ControllerObserver
  model: 'Organization'
  observe:
    member_ids: true
  observeNot:
    cid: true
    created_at: true
    created_by_id: true
    updated_at: true
    updated_by_id: true
    preferences: true
    source: true
    image_source: true

  events:
    'focusout [contenteditable]': 'update'

  render: (organization) =>

    # update taskbar with new meta data
    App.TaskManager.touch(@taskKey)

    # get display data
    organizationData = []
    for attributeName, attributeConfig of App.Organization.attributesGet('view')

      # check if value for _id exists
      name    = attributeName
      nameNew = name.substr(0, name.length - 3)
      if nameNew of organization
        name = nameNew

      # add to show if value exists
      if (organization[name] || attributeConfig.tag is 'richtext') && attributeConfig.shown

        # do not show firstname and lastname / already show via diplayName()
        if name isnt 'name'
          organizationData.push attributeConfig

    @html App.view('organization_profile/object')(
      organization:     organization
      organizationData: organizationData
    )

    @$('[contenteditable]').ce({
      mode:      'textonly'
      multiline: true
      maxlength: 250
    })

    # show members
    members = []
    for userId in organization.member_ids
      el = $('<div></div>')
      new Member(
        object_id: userId
        el: el
      )
      members.push el
    @$('.js-userList').html(members)

  update: (e) =>
    name  = $(e.target).attr('data-name')
    value = $(e.target).html()
    org   = App.Organization.find(@object_id)
    if org[name] isnt value
      @lastAttributres[name] = value
      data = {}
      data[name] = value
      org.updateAttributes(data)
      @log 'debug', 'update', name, value, org

class Organization extends App.ControllerObserver
  model: 'Organization'
  observe:
    name: true

  render: (organization) =>
    @html App.Utils.htmlEscape(organization.displayName())

class Member extends App.ControllerObserver
  model: 'User'
  observe:
    firstname: true
    lastname: true
    login: true
    email: true
    active: true
    image: true
  globalRerender: false

  render: (user) =>
    @html App.view('organization_profile/member')(
      user: user
    )

class Router extends App.ControllerPermanent
  requiredPermission: 'ticket.agent'
  constructor: (params) ->
    super

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

class App.WidgetOrganization extends App.Controller
  memberLimit: 10

  events:
    'click .js-showMoreMembers': 'showMoreMembers'
    'focusout [contenteditable]': 'update'

  constructor: ->
    super

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = App.Organization.full(@organization_id, @render, false, true)

  release: =>
    App.Organization.unsubscribe(@subscribeId)

  showMoreMembers: (e) ->
    @preventDefaultAndStopPropagation(e)
    @memberLimit = (parseInt(@memberLimit / 100) + 1) * 100
    @renderMembers()

  renderMembers: ->
    elLocal = @el
    @organization.members(0, @memberLimit, (users) ->
      members = []
      for user in users
        el = $('<div></div>')
        new Member(
          object_id: user.id
          el: el
        )
        members.push el
      elLocal.find('.js-userList').html(members)
    )

    if @organization.member_ids.length <= @memberLimit
      @el.find('.js-showMoreMembers').parent().addClass('hidden')
    else
      @el.find('.js-showMoreMembers').parent().removeClass('hidden')

  organizationData: ->
    # get display data
    organizationData = []
    for attributeName, attributeConfig of App.Organization.attributesGet('view')

      # check if value for _id exists
      name    = attributeName
      nameNew = name.substr( 0, name.length - 3 )
      if nameNew of @organization
        name = nameNew

      # do not show name since it's already shown via diplayName()
      continue if name is 'name'

      # do not show if configured to be not shown
      continue if !attributeConfig.shown

      # Fix for issue #2277 - note is not shown for customer/organisations if it's empty
      # Always show for these two conditions:
      # 1. the attribute exists and is not empty
      # 2. it is a richtext note field
      continue if ( !@organization[name]? || @organization[name] is '' ) && attributeConfig.tag isnt 'richtext'

      # add to show if all checks passed
      organizationData.push attributeConfig
    return organizationData

  render: (organization) =>
    if organization
      @organization = organization
    else if !@organization
      @organization = @u

    return @renderAgent(organization) if @permissionCheck('ticket.agent')
    @renderCustomer(organization)

  renderCustomer: (organization) ->
    # get display data
    organizationData = @organizationData()

    # insert userData
    @html $(App.view('widget/organization')(
      organization:     @organization
      organizationData: organizationData
      customer: true
    ))

  renderAgent: (organization) =>
    # get display data
    organizationData = @organizationData()

    # insert userData
    elLocal = $(App.view('widget/organization')(
      organization:     @organization
      organizationData: organizationData
    ))

    @html elLocal

    @renderMembers()

    @$('[contenteditable]').ce(
      mode:      'textonly'
      multiline: true
      maxlength: 250
    )

  update: (e) =>
    name  = $(e.target).attr('data-name')
    value = $(e.target).html()
    org   = App.Organization.find(@organization_id)
    if org[name] isnt value
      data = {}
      data[name] = value
      org.updateAttributes(data)
      @log 'notice', 'update', name, value, org

class Member extends App.ControllerObserver
  @extend App.PopoverProvidable
  @registerPopovers 'User'

  model: 'User'
  observe:
    firstname: true
    lastname: true
    image: true
    active: true

  render: (user) =>
    @html App.view('organization_profile/member')(
      user: user
      el: @el,
    )

    @renderPopovers()

class App.WidgetOrganization extends App.Controller

  events:
    'focusout [contenteditable]': 'update'

  constructor: ->
    super

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = App.Organization.full(@organization_id, @render, false, true)

  release: =>
    App.Organization.unsubscribe(@subscribeId)

  render: (organization) =>
    if !organization
      organization = @u

    # get display data
    organizationData = []
    for attributeName, attributeConfig of App.Organization.attributesGet('view')

      # check if value for _id exists
      name    = attributeName
      nameNew = name.substr( 0, name.length - 3 )
      if nameNew of organization
        name = nameNew

      # do not show name since it's already shown via diplayName()
      continue if name is 'name'

      # do not show if configured to be not shown
      continue if !attributeConfig.shown

      # Fix for issue #2277 - note is not shown for customer/organisations if it's empty
      # Always show for these two conditions:
      # 1. the attribute exists and is not empty
      # 2. it is a richtext note field
      continue if ( !organization[name]? || organization[name] is '' ) && attributeConfig.tag isnt 'richtext'

      # add to show if all checks passed
      organizationData.push attributeConfig

    # insert userData
    elLocal = $(App.view('widget/organization')(
      organization:     organization
      organizationData: organizationData
    ))

    for user in organization.members
      new User(
        object_id: user.id
        el: elLocal.find('div.userList-row[data-id=' + user.id + ']')
      )

    @html elLocal

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

class User extends App.ControllerObserver
  @extend App.PopoverProvidable
  @registerPopovers 'User'

  model: 'User'
  observe:
    firstname: true
    lastname: true
    image: true

  render: (user) =>
    @html App.view('organization_profile/member')(
      user: user
      el: @el,
    )

    @renderPopovers()

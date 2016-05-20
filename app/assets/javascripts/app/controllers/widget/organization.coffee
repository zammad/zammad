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

      # add to show if value exists
      if ( organization[name] || attributeConfig.tag is 'richtext' ) && attributeConfig.shown

        # do not show firstname and lastname / already show via diplayName()
        if name isnt 'name'
          organizationData.push attributeConfig

    # insert userData
    @html App.view('widget/organization')(
      organization:     organization
      organizationData: organizationData
    )

    @$('[contenteditable]').ce(
      mode:      'textonly'
      multiline: true
      maxlength: 250
    )

    # enable user popups
    @userPopups()

    ###
    @userTicketPopups(
      selector: '.user-tickets'
      user_id:  user.id
      position: 'right'
    )
    ###

  update: (e) =>
    name  = $(e.target).attr('data-name')
    value = $(e.target).html()
    org   = App.Organization.find(@organization_id)
    if org[name] isnt value
      data = {}
      data[name] = value
      org.updateAttributes(data)
      @log 'notice', 'update', name, value, org

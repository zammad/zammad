class App.WidgetOrganization extends App.Controller
  events:
    'focusout [data-type=update-org]':  'update',
    'click [data-type=edit-org]':       'edit'

  constructor: ->
    super

    # show organization
    callback = (organization) =>
      @render(organization)
      if @callback
        @callback(organization)

      # subscribe and reload data / fetch new data if triggered
      @subscribeId = organization.subscribe(@render)

    App.Organization.retrieve( @organization_id, callback )

  release: =>
    App.Organization.unsubscribe(@subscribeId)

  render: (organization) =>
    if !organization
      organization = @u

    # get display data
    organizationData = []
    for item2 in App.Organization.configure_attributes
      item = _.clone( item2 )

      # check if value for _id exists
      itemNameValue = item.name
      itemNameValueNew = itemNameValue.substr( 0, itemNameValue.length - 3 )
      if itemNameValueNew of organization
        item.name = itemNameValueNew

      # add to show if value exists
      if organization[item.name] || item.tag is 'textarea'

        # do not show name / already show via diplayName()
        if item.name isnt 'name'
          if item.info
            organizationData.push item

    # insert userData
    @html App.view('widget/organization')(
      organization:     organization
      organizationData: organizationData
    )

    a = =>
      @el.find('textarea').expanding()
      @el.find('textarea').on('focus', =>
        @el.find('textarea').expanding()
      )
    @delay( a, 80 )

    ###
    @userTicketPopups(
      selector: '.user-tickets'
      user_id:  user.id
      position: 'right'
    )
    ###

  update: (e) =>
    note   = $(e.target).parent().find('[data-type=update]').val()
    organization = App.Organization.find( @organization_id )
    if organization.note isnt note
      organization.updateAttributes( note: note )
      @log 'notice', 'update', e, note, organization

  edit: (e) =>
    e.preventDefault()
    new App.ControllerGenericEdit(
      id: @organization_id,
      genericObject: 'Organization',
      pageData: {
        title: 'Organizations',
        object: 'Organization',
        objects: 'Organizations',
      },
      callback: @render
    )

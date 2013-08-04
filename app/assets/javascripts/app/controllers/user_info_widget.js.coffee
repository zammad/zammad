class App.UserInfo extends App.Controller
  events:
    'focusout [data-type=update-user]': 'update_user',
    'focusout [data-type=update-org]':  'update_org',
    'click [data-type=edit-user]':      'edit_user'
    'click [data-type=edit-org]':       'edit_org'
    'click .nav li > a':                'toggle'

  constructor: ->
    super

    # show user
    callback = (user) =>
      @render(user)
      if @callback
        @callback(user)

      # subscribe and reload data / fetch new data if triggered
      @subscribeId = user.subscribe(@render)

    App.User.retrieve( @user_id, callback )

  release: =>
    App.User.unsubscribe(@subscribeId)

  toggle: (e) ->
    e.preventDefault()
    @el.find('.nav li.active').removeClass('active')
    $(e.target).parent('li').addClass('active')
    area = $(e.target).data('area')
    @el.find('.user-info, .org-info').addClass('hide')
    @el.find('.' + area ).removeClass('hide')

  render: (user) =>
    if !user
      user = @u

    # get display data
    userData = []
    for item2 in App.User.configure_attributes
      item = _.clone( item2 )

      # check if value for _id exists
      itemNameValue = item.name
      itemNameValueNew = itemNameValue.substr( 0, itemNameValue.length - 3 )
      if itemNameValueNew of user
        item.name = itemNameValueNew

      # add to show if value exists
      if user[item.name] || item.tag is 'textarea'

        # do not show firstname and lastname / already show via diplayName()
        if item.name isnt 'firstname' && item.name isnt 'lastname' && item.name isnt 'organization'
          if item.info
            userData.push item

    if user.organization_id
      organization = App.Organization.find( user.organization_id )
      organizationData = []
      for item2 in App.Organization.configure_attributes
        item = _.clone( item2 )

        # check if value for _id exists
        itemNameValue = item.name
        itemNameValueNew = itemNameValue.substr( 0, itemNameValue.length - 3 )
        if itemNameValueNew of user
          item.name = itemNameValueNew

        # add to show if value exists
        if organization[item.name] || item.tag is 'textarea'

          # do not show name / already show via diplayName()
          if item.name isnt 'name'
            if item.info
              organizationData.push item

    # insert userData
    @html App.view('user_info')(
      user:             user
      userData:         userData
      organization:     organization
      organizationData: organizationData
    )

    @userTicketPopups(
      selector: '.user-tickets'
      user_id:  user.id
      position: 'right'
    )

  update_user: (e) =>
    note = $(e.target).parent().find('[data-type=update-user]').val()
    user = App.User.find( @user_id )
    if user.note isnt note
      user.updateAttributes( note: note )
      @log 'notice', 'update', e, note, user

  edit_user: (e) =>
    e.preventDefault()
    new App.ControllerGenericEdit(
      id: @user_id,
      genericObject: 'User',
      required: 'quick',
      pageData: {
        title: 'Users',
        object: 'User',
        objects: 'Users',
      },
      callback: @render
    )

  update_org: (e) =>
    note   = $(e.target).parent().find('[data-type=update-org]').val()
    org_id = $(e.target).parents().find('[data-type=edit-org]').data('id')
    organization = App.Organization.find( org_id )
    if organization.note isnt note
      organization.updateAttributes( note: note )
      @log 'notice', 'update', e, note, organization

  edit_org: (e) =>
    e.preventDefault()
    id = $(e.target).data('id')
    new App.ControllerGenericEdit(
      id: id,
      genericObject: 'Organization',
      pageData: {
        title: 'Organizations',
        object: 'Organization',
        objects: 'Organizations',
      },
      callback: @render
    )

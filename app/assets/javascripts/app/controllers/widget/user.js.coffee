class App.WidgetUser extends App.ControllerDrox
  events:
    'focusout [data-type=update]': 'update',
    'click [data-type=edit]':      'edit'

  constructor: ->
    super

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = App.User.full( @user_id, @render, false, true )

  release: =>
    App.User.unsubscribe(@subscribeId)

  render: (user) =>

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
        if item.name isnt 'firstname' && item.name isnt 'lastname'
          if item.info
            userData.push item

    if user.preferences
      items = []
      if user.preferences.tickets_open > 0
        item =
          url: ''
          name: 'open'
          count: user.preferences.tickets_open
          title: 'Open Tickets'
          class: 'user-tickets'
          data:  'open'
        items.push item
      if user.preferences.tickets_closed > 0
        item =
          url: ''
          name: 'closed'
          count: user.preferences.tickets_closed
          title: 'Closed Tickets'
          class: 'user-tickets'
          data:  'closed'
        items.push item

      if items[0]
        topic =
          title: 'Tickets'
          items: items
        user['links'] = []
        user['links'].push topic

    # insert userData
    @html @template(
      file:   'widget/user'
      header: 'Customer'
      edit:   true
      params:
        user:     user
        userData: userData
    )

    a = =>
      @el.find('textarea').expanding()
      @el.find('textarea').on('focus', =>
        @el.find('textarea').expanding()
      )
    @delay( a, 80 )

    @userTicketPopups(
      selector: '.user-tickets'
      user_id:  user.id
      position: 'right'
    )

    if user.organization_id
      @el.append('<div class="org-info"></div>')
      new App.WidgetOrganization(
        organization_id: user.organization_id
        el:              @el.find('.org-info')
      )

  update: (e) =>
    note = $(e.target).val()
    user = App.User.find( @user_id )
    if user.note isnt note
      user.updateAttributes( note: note )
      @log 'notice', 'update', e, note, user

  edit: (e) =>
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

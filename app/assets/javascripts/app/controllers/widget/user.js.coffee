class App.WidgetUser extends App.Controller
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

    # execute callback on render/rerender
    if @callback
      @callback(user)

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
    @html App.view('widget/user')(
      header: 'Customer'
      edit:   true
      user:     user
      userData: userData
    )

    @$('div[contenteditable]').ce(
      mode:      'textonly'
      multiline: true
      maxlength: 250
    )

    @userTicketPopups(
      selector: '.user-tickets'
      user_id:  user.id
      position: 'right'
    )

  update: (e) =>
    note = $(e.target).ceg({ mode: 'textonly' })
    user = App.User.find( @user_id )
    if user.note isnt note
      user.updateAttributes( note: note )
      @log 'notice', 'update', e, note, user

  edit: (e) =>
    e.preventDefault()
    new App.ControllerGenericEdit(
      id: @user_id
      genericObject: 'User'
      screen: 'edit'
      pageData:
        title: 'Users'
        object: 'User'
        objects: 'Users'
      callback: @render
    )

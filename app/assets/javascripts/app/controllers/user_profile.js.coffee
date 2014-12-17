class App.UserProfile extends App.Controller
  events:
    'focusout [contenteditable]': 'update'

  constructor: (params) ->
    super

    # check authentication
    if !@authenticate()
      App.TaskManager.remove( @task_key )
      return

    @navupdate '#'

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = App.User.full( @user_id, @render, false, true )

  release: =>
    App.User.unsubscribe(@subscribeId)

  meta: =>
    meta =
      url: @url()
      id:  @user_id

    if App.User.exists( @user_id )
      user = App.User.find( @user_id )

      meta.head       = user.displayName()
      meta.title      = user.displayName()
      meta.iconClass  = user.icon()
    meta

  url: =>
    '#user/profile/' + @user_id

  show: =>
    App.OnlineNotification.seen( 'User', @user_id )
    @navupdate '#'

  changed: =>
    false

  render: (user) =>

    if !@doNotLog
      @doNotLog = 1
      @recentView( 'User', @user_id )

    # get display data
    userData = []
    for attributeName, attributeConfig of App.User.attributesGet('view')

      # check if value for _id exists
      name    = attributeName
      nameNew = name.substr( 0, name.length - 3 )
      if nameNew of user
        name = nameNew

      # add to show if value exists
      if user[name] && attributeConfig.shown

        # do not show firstname and lastname / already show via diplayName()
        if name isnt 'firstname' && name isnt 'lastname' && name isnt 'organization'
          userData.push attributeConfig

    @html App.view('user_profile')(
      user:     user
      userData: userData
    )

    @$('[contenteditable]').ce({
      mode:      'textonly'
      multiline: true
      maxlength: 250
    })

    new App.TicketStats(
      el:   @$('.js-ticket-stats')
      user: user
    )

    new App.UpdateTastbar(
      genericObject: user
    )

    # start action controller
    showHistory = =>
      new App.UserHistory( user_id: user.id )

    editUser = =>
      new App.ControllerGenericEdit(
        id: user.id
        genericObject: 'User'
        screen: 'edit'
        pageData:
          title: 'Users'
          object: 'User'
          objects: 'Users'
      )

    actions = [
      {
        name:     'edit'
        title:    'Edit'
        callback: editUser
      }
      {
        name:     'history'
        title:    'History'
        callback: showHistory
      }
    ]

    new App.ActionRow(
      el:    @el.find('.js-action')
      items: actions
    )

  update: (e) =>
    name  = $(e.target).attr('data-name')
    value = $(e.target).html()
    user  = App.User.find( @user_id )
    if user[name] isnt value
      data = {}
      data[name] = value
      user.updateAttributes( data )
      @log 'notice', 'update', name, value, user

class Router extends App.ControllerPermanent
  constructor: (params) ->
    super

    # cleanup params
    clean_params =
      user_id:  params.user_id

    App.TaskManager.add( 'User-' + @user_id, 'UserProfile', clean_params )

App.Config.set( 'user/profile/:user_id', Router, 'Routes' )

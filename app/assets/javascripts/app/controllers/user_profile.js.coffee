class App.UserProfile extends App.Controller
  events:
    'focusout [data-type=update]': 'update'

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
    console.log('update')
    note = $(e.target).ceg()
    user = App.User.find( @user_id )
    if user.note isnt note
      user.updateAttributes( note: note )
      @log 'notice', 'update', e, note, user

class Router extends App.ControllerPermanent
  constructor: (params) ->
    super

    # cleanup params
    clean_params =
      user_id:  params.user_id

    App.TaskManager.add( 'User-' + @user_id, 'UserProfile', clean_params )

App.Config.set( 'user/profile/:user_id', Router, 'Routes' )

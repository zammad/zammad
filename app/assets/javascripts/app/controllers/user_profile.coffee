class App.UserProfile extends App.Controller
  @requiredPermission: ['ticket.agent', 'admin.user']

  constructor: (params) ->
    super
    @init = params.init

    # fetch new data if needed
    App.User.full(@user_id, @render)

  meta: =>
    meta =
      url: @url()
      id:  @user_id

    if App.User.exists(@user_id)
      user = App.User.find(@user_id)
      icon = user.icon()

      if user.active is false
        icon = 'inactive-' + icon

      meta.head       = user.displayName()
      meta.title      = user.displayName()
      meta.iconClass  = icon
      meta.active     = user.active
    meta

  url: =>
    '#user/profile/' + @user_id

  show: =>
    App.OnlineNotification.seen('User', @user_id)
    @navupdate(url: '#', type: 'menu')

  changed: ->
    false

  render: (user) =>

    if !@doNotLog
      @doNotLog = 1
      @recentView('User', @user_id)

    elLocal = $(App.view('user_profile/index')(
      user: user
    ))

    new App.UserProfileUser(
      object_id: user.id
      el: elLocal.find('.js-profileName')
    )

    new App.UserProfileObject(
      el:        elLocal.find('.js-object-container')
      object_id: user.id
      taskKey:  @taskKey
    )

    new App.UserProfileActionRow(
      el:        elLocal.find('.js-action')
      object_id: user.id
    )

    new App.TicketStats(
      el:   elLocal.find('.js-ticket-stats')
      user: user
      init: @init
    )

    @html elLocal

    new App.UpdateTaskbar(
      genericObject: user
    )

  setPosition: (position) =>
    @$('.profile').scrollTop(position)

  currentPosition: =>
    @$('.profile').scrollTop()

class Router extends App.ControllerPermanent
  @requiredPermission: ['ticket.agent', 'admin.user']

  constructor: (params) ->
    super

    # check authentication
    @authenticateCheckRedirect()

    # cleanup params
    clean_params =
      user_id:  params.user_id

    App.TaskManager.execute(
      key:        "User-#{@user_id}"
      controller: 'UserProfile'
      params:     clean_params
      show:       true
    )

App.Config.set('user/profile/:user_id', Router, 'Routes')

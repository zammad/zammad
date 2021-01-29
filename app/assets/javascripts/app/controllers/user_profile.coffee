class App.UserProfile extends App.Controller
  constructor: (params) ->
    super

    # check authentication
    @authenticateCheckRedirect()

    # fetch new data if needed
    App.User.full(@user_id, @render)

  meta: =>
    meta =
      url: @url()
      id:  @user_id

    if App.User.exists(@user_id)
      user = App.User.find(@user_id)

      meta.head       = user.displayName()
      meta.title      = user.displayName()
      meta.iconClass  = user.icon()
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

    new User(
      object_id: user.id
      el: elLocal.find('.js-profileName')
    )

    new Object(
      el:        elLocal.find('.js-object-container')
      object_id: user.id
      taskKey:  @taskKey
    )

    new ActionRow(
      el:        elLocal.find('.js-action')
      object_id: user.id
    )

    new App.TicketStats(
      el:   elLocal.find('.js-ticket-stats')
      user: user
    )

    @html elLocal

    new App.UpdateTastbar(
      genericObject: user
    )

  setPosition: (position) =>
    @$('.profile').scrollTop(position)

  currentPosition: =>
    @$('.profile').scrollTop()

class ActionRow extends App.ControllerObserverActionRow
  model: 'User'
  observe:
    verified: true
    source: true
    organization_id: true

  showHistory: (user) =>
    new App.UserHistory(
      user_id: user.id
      container: @el.closest('.content')
    )

  editUser: (user) =>
    new App.ControllerGenericEdit(
      id: user.id
      genericObject: 'User'
      screen: 'edit'
      pageData:
        title: 'Users'
        object: 'User'
        objects: 'Users'
      container: @el.closest('.content')
    )

  newTicket: (user) =>
    @navigate("ticket/create/customer/#{user.id}")

  resendVerificationEmail: (user) =>
    @ajax(
      id:          'email_verify_send'
      type:        'POST'
      url:         @apiPath + '/users/email_verify_send'
      data:        JSON.stringify(email: user.email)
      processData: true
      success: (data, status, xhr) =>
        @notify
          type:      'success'
          msg:       App.i18n.translateContent('Email sent to "%s". Please let the user verify his email address.', user.email)
          removeAll: true
      error: (data, status, xhr) =>
        @notify
          type:      'error'
          msg:       App.i18n.translateContent('Failed to sent Email "%s". Please contact an administrator.', user.email)
          removeAll: true
    )

  actions: (user) =>
    actions = [
      {
        name:     'history'
        title:    'History'
        callback: @showHistory
      }
      {
        name:     'ticket'
        title:    'New Ticket'
        callback: @newTicket
      }
    ]

    if user.isAccessibleBy(App.User.current(), 'change')
      actions.unshift {
        name:     'edit'
        title:    'Edit'
        callback: @editUser
      }

      if user.verified isnt true && user.source is 'signup'
        actions.push({
          name:     'resend_verification_email'
          title:    'Resend verification email'
          callback: @resendVerificationEmail
        })

    if @permissionCheck('admin.data_privacy')
      actions.push {
        title:    'Delete'
        name:     'delete'
        callback: =>
          @navigate "#system/data_privacy/#{user.id}"
      }

    actions

class Object extends App.ControllerObserver
  model: 'User'
  observeNot:
    cid: true
    created_at: true
    created_by_id: true
    updated_at: true
    updated_by_id: true
    preferences: true
    password: true
    last_login: true
    login_failed: true
    source: true
    image_source: true

  events:
    'focusout [contenteditable]': 'update'

  render: (user) =>

    # update taskbar with new meta data
    App.TaskManager.touch(@taskKey)

    # get display data
    userData = []
    for attributeName, attributeConfig of App.User.attributesGet('view')

      # check if value for _id exists
      name    = attributeName
      nameNew = name.substr(0, name.length - 3)
      if nameNew of user
        name = nameNew

      # add to show if value exists
      if (user[name] || attributeConfig.tag is 'richtext') && attributeConfig.shown

        # do not show firstname and lastname / already show via diplayName()
        if name isnt 'firstname' && name isnt 'lastname' && name isnt 'organization'
          userData.push attributeConfig

    @html App.view('user_profile/object')(
      user:     user
      userData: userData
    )

    @$('[contenteditable]').ce({
      mode:      'textonly'
      multiline: true
      maxlength: 250
    })

  update: (e) =>
    name  = $(e.target).attr('data-name')
    value = $(e.target).html()
    user  = App.User.find(@object_id)
    if user[name] isnt value
      @lastAttributres[name] = value
      data = {}
      data[name] = value
      user.updateAttributes(data)
      @log 'debug', 'update', name, value, user

class Organization extends App.ControllerObserver
  model: 'Organization'
  observe:
    name: true

  render: (organization) =>
    @html App.view('user_profile/organization')(
      organization: organization
    )

class User extends App.ControllerObserver
  model: 'User'
  observe:
    firstname: true
    lastname: true
    organization_id: true
    image: true

  render: (user) =>
    if user.organization_id
      new Organization(
        object_id: user.organization_id
        el: @el.siblings('.js-organization')
      )

    @html App.view('user_profile/name')(
      user: user
    )

class Router extends App.ControllerPermanent
  requiredPermission: 'ticket.agent'
  constructor: (params) ->
    super

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

class App.UserOrganizationAutocompletion extends App.ObjectOrganizationAutocompletion
  objectSingle: 'User'
  objectIcon: 'user'
  inactiveObjectIcon: 'inactive-user'
  objectSingels: 'People'
  objectCreate: 'Create new Customer'
  referenceAttribute: 'member_ids'

  newObject: (e) =>
    if e
      e.preventDefault()
    new UserNew(
      parent:    @
      container: @el.closest('.content')
    )

  buildObjectItem: (object) =>
    realname = object.displayName()
    if @Config.get('ui_user_organization_selector_with_email') && !_.isEmpty(object.email)
      realname += " <#{object.email}>"

    icon = @objectIcon

    if object.active is false and @inactiveObjectIcon
      icon = @inactiveObjectIcon

    App.view(@templateObjectItem)(
      realname: realname
      object: object
      icon: icon
    )

class UserNew extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: 'User'
  headPrefix: 'New'

  content: ->
    @controller = new App.ControllerForm(
      model:     App.User
      screen:    'edit'
      autofocus: true
    )
    @controller.form

  onSubmit: (e) =>
    params = @formParam(e.target)

    # if no login is given, use emails as fallback
    if !params.login && params.email
      params.login = params.email

    # find role_id
    if !params.role_ids || _.isEmpty(params.role_ids)
      role_ids = []
      for role of App.Role.all()
        if role && role.active is true && role.default_at_signup is true
          role_ids.push role.id
      params.role_ids = role_ids
    @log 'notice', 'updateAttributes', params

    user = new App.User
    user.load(params)

    errors = user.validate()
    if errors
      @log 'error', errors
      @formValidate(form: e.target, errors: errors)
      return

    # save user
    ui = @
    user.save(
      done: ->

        # force to reload object
        callbackReload = (user) ->
          ui.parent.el.find('[name=customer_id]').val(user.id).trigger('change')
          ui.parent.close()

          # start customer info controller
          ui.close()
        App.User.full(@id, callbackReload , true)

      fail: (settings, details) ->
        ui.log 'errors', details
        ui.formEnable(e)
        ui.controller.showAlert(details.error_human || details.error || 'Unable to create object!')
    )

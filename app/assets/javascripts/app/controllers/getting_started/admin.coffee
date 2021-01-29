class GettingStartedAdmin extends App.ControllerWizardFullScreen
  events:
    'submit form': 'submit'

  constructor: ->
    super

    if @authenticateCheck() && !@permissionCheck('admin.wizard')
      @navigate '#'
      return

    # set title
    @title 'Create Admin'

    # redirect to login if master user already exists
    if @Config.get('system_init_done')
      @navigate '#login'
      return

    @fetch()

  fetch: ->

    # get data
    @ajax(
      id:    'getting_started'
      type:  'GET'
      url:   "#{@apiPath}/getting_started"
      processData: true
      success: (data, status, xhr) =>

        # check if user got created right now
        #if true
        #  @navigate '#getting_started/base', { emptyEl: true }
        #  return

        # check if import is active
        if data.import_mode == true
          @navigate "#import/#{data.import_backend}", { emptyEl: true }
          return

        # load group collection
        App.Collection.load(type: 'Group', data: data.groups)

        # render page
        @render()
    )

  render: ->

    @replaceWith(App.view('getting_started/admin')())

    @form = new App.ControllerForm(
      el:        @$('.js-admin-form')
      model:     App.User
      screen:    'signup'
      autofocus: true
    )

  submit: (e) =>
    e.preventDefault()
    @formDisable(e)
    @params          = @formParam(e.target)
    @params.role_ids = []

    user = new App.User
    user.load(@params)

    errors = user.validate(
      screen: 'signup'
    )
    if errors
      @log 'error new', errors

      # Only highlight, but don't add message. Error text breaks layout.
      Object.keys(errors).forEach (key) ->
        errors[key] = null

      @formValidate(form: e.target, errors: errors)
      @formEnable(e)
      return false
    else
      @formValidate(form: e.target, errors: errors)

    # save user
    user.save(
      done: (r) =>
        App.Auth.login(
          data:
            username: @params.email
            password: @params.password
          success: @relogin
          error: ->
            App.Event.trigger('notify', {
              type:    'error'
              msg:     App.i18n.translateContent('Signin failed! Please contact the support team!')
              timeout: 2500
            })
        )
        @Config.set('system_init_done', true)

      fail: (settings, details) =>
        @formEnable(e)
        @form.showAlert(details.error_human || details.error || 'Unable to create user!')
    )

  relogin: (data, status, xhr) =>
    @log 'notice', 'relogin:success', data
    App.Event.trigger('notify:removeall')
    @navigate('getting_started/base', { emptyEl: true })

App.Config.set('getting_started/admin', GettingStartedAdmin, 'Routes')

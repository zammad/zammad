class GettingStartedAgent extends App.ControllerWizardFullScreen
  events:
    'submit form': 'submit'

  constructor: ->
    super
    @authenticateCheckRedirect()

    # set title
    @title 'Invite Agents'
    @fetch()

  fetch: ->

    # get data
    @ajax(
      id:    'getting_started'
      type:  'GET'
      url:   "#{@apiPath}/getting_started"
      processData: true
      success: (data, status, xhr) =>

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

    @replaceWith App.view('getting_started/agent')()

    @form = new App.ControllerForm(
      el:        @$('.js-agent-form')
      model:     App.User
      screen:    'invite_agent'
      autofocus: true
    )

  submit: (e) =>
    e.preventDefault()
    @formDisable(e)
    @params          = @formParam(e.target)
    @params.role_ids = []

    # set invite flag
    @params.invite = true

    # find agent role
    role = App.Role.findByAttribute('name', 'Agent')
    if role
      @params.role_ids = role.id

    user = new App.User
    user.load(@params)

    errors = user.validate(
      screen: 'invite_agent'
    )
    if errors
      @log 'error new', errors
      @formValidate(form: e.target, errors: errors)
      @formEnable(e)
      return false

    # save user
    user.save(
      done: (r) =>
        App.Event.trigger('notify', {
          type:    'success'
          msg:     App.i18n.translateContent('Invitation sent!')
          timeout: 3500
        })

        # rerender page
        @render()

      fail: (settings, details) =>
        @formEnable(e)
        @form.showAlert(details.error_human || 'Can\'t create user!')
    )

App.Config.set('getting_started/agents', GettingStartedAgent, 'Routes')

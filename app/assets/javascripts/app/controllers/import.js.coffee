class Index extends App.ControllerContent
  className: 'getstarted fit'

  events:
    'submit form':   'submit',
    'click .submit': 'submit',

  constructor: ->
    super

    # set title
    @title 'Get Started'
    @navupdate '#get_started'

    @master_user = 0
    @fetch()

  fetch: ->

    # get data
    @ajax(
      id:    'getting_started',
      type:  'GET',
      url:   @apiPath + '/getting_started',
      data:  {
#        view:       @view,
      }
      processData: true,
      success: (data, status, xhr) =>

        # get meta data
        @master_user = data.master_user

        # load group collection
        App.Collection.load( type: 'Group', data: data.groups )

        # render page
        @render()
    )

  render: ->

    # check authentication, redirect to login if master user already exists
    #if !@master_user && !@authenticate()
    #  @navigate '#login'

    @html App.view('getting_started')(
      master_user: @master_user
    )

    new App.ControllerForm(
      el:        @el.find('#form-master')
      model:     App.User
      screen:    'signup'
      autofocus: true
    )
    new App.ControllerForm(
      el:        @el.find('#form-agent')
      model:     App.User
      screen:    'invite_agent'
      autofocus: true
    )

    if !@master_user
      @el.find('.agent_user').removeClass('hide')

  submit: (e) ->
    e.preventDefault()
    @params = @formParam(e.target)

    # if no login is given, use emails as fallback
    if !@params.login && @params.email
      @params.login = @params.email

    # set invite flag
    @params.invite = true

    # find agent role
    role = App.Role.findByAttribute( 'name', 'Agent' )
    if role
      @params.role_ids = role.id
    else
      @params.role_ids = [0]

    @log 'notice', 'updateAttributes', @params
    user = new App.User
    user.load(@params)

    errors = user.validate()
    if errors
      @log 'error', errors
      @formValidate( form: e.target, errors: errors )
      return false

    # save user
    user.save(
      done: =>
        if @master_user
          @master_user = false
          App.Auth.login(
            data: {
              username: @params.login
              password: @params.password
            },
            success: @relogin
#            error: @error,
          )
          @Config.set('system_init_done', true)
          App.Event.trigger 'notify', {
            type:    'success'
            msg:     App.i18n.translateContent( 'Welcome to %s!', @Config.get('product_name') )
            timeout: 2500
          }

        else

          App.Event.trigger 'notify', {
            type:    'success'
            msg:     App.i18n.translateContent( 'Invitation sent!' )
            timeout: 3500
          }

          # rerender page
          @render()

      fail: (data) ->
        App.Event.trigger 'notify', {
          type:    'error'
          msg:     App.i18n.translateContent( 'Can\'t create user!' )
          timeout: 2500
        }
#        @modalHide()
    )

  relogin: (data, status, xhr) =>
    @log 'notice', 'relogin:success', data

    # add notify
    App.Event.trigger 'notify:removeall'
#      @notify
#        type: 'success',
#        msg: 'Thanks for joining. Email sent to "' + @params.email + '". Please verify your email address.'

    @el.find('.master_user').addClass('hide')
    @el.find('.agent_user').removeClass('hide')
    @el.find('.tabs .tab.active').removeClass('active')
    @el.find('.tabs .invite_agents').addClass('active')
#    @el.find('.master_user').fadeOut('slow', =>
#      @el.find('.agent_user').fadeIn()
#    )

App.Config.set( 'import', Index, 'Routes' )

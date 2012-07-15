$ = jQuery.sub()

class Index extends App.Controller
  className: 'container getstarted'

  events:
    'submit form':   'submit',
    'click .submit': 'submit',

  constructor: ->
    super
    
    # set title
    @title 'Get Started'
    @navupdate '#get_started'
 
    @master_user = 0
 
#    @render()
    @fetch()

  fetch: ->

    # get data
    App.Com.ajax(
      id:    'getting_started',
      type:  'GET',
      url:   '/getting_started',
      data:  {
#        view:       @view,
      }
      processData: true,
      success: (data, status, xhr) =>

        # get meta data
        @master_user = data.master_user

        # load group collection
        @loadCollection( type: 'Group', data: data.groups )

        # render page
        @render()
    )

  render: ->
    
    # check authentication, redirect to login if master user already exists
    if !@master_user && !@authenticate()
      @navigate '#login'

    @html App.view('getting_started')(
      form_agent:  @formGen( model: App.User, required: 'invite_agent' ),
      form_master: @formGen( model: App.User, required: 'signup' ),
      master_user: @master_user,
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
    role = App.Role.findByAttribute("name", "Agent")
    if role
      @params.role_ids = role.id
    else
      @params.role_ids = [0]

    @log 'updateAttributes', @params
    user = new App.User
    user.load(@params)

    errors = user.validate()
    if errors
      @log 'error new', errors
      @validateForm( form: e.target, errors: errors )
      return false

    # save user
    user.save(
      success: (r) =>

        if @master_user
          @master_user = false
          auth = new App.Auth
          auth.login(
            data: {
              username: @params.login,
              password: @params.password,
            },
            success: @relogin
#            error: @error,
          )
        else

          # rerender page    
          @render()
          
#      error: =>
#        @modalHide()
    )


  relogin: (data, status, xhr) =>
    @log 'login:success', data

    # login check
    auth = new App.Auth
    auth.loginCheck()
  
    # add notify
    Spine.trigger 'notify:removeall'
#      @notify
#        type: 'success',
#        msg: 'Thanks for joining. Email sent to "' + @params.email + '". Please verify your email address.'
      
    @el.find('.master_user').fadeOut('slow', =>
      @el.find('.agent_user').fadeIn()
    )


    
Config.Routes['getting_started'] = Index

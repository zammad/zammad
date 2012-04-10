$ = jQuery.sub()

class Index extends App.Controller
  className: 'container getstarted'

  events:
    'submit form': 'submit',
    'click .submit': 'submit',

  constructor: ->
    super
    
    # check authentication
    return if !@authenticate()
    
    # set title
    @title 'Get Started'

    @render()

    @navupdate '#get_started'
    
  render: ->
    @html App.view('getting_started')(
      form: @formGen( model: App.User, required: 'invite_agent' ),
    )

  cancel: ->
    @log 'cancel....'
    @navigate 'login'

  submit: (e) ->
    @log 'submit'
    e.preventDefault()
    @params = @formParam(e.target)
    
    # if no login is given, use emails as fallback
    if !@params.login && @params.email
      @params.login = @params.email

    # find agent role
    role = App.Role.findByAttribute("name", "Agent")
    @params.role_ids = role.id
    
    # set invite flag
    @params.invite = true

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
        # send email
        
        # clear form
        @render()
#      error: =>
#        @modalHide()
    )

Config.Routes['getting_started'] = Index

#class App.GetStarted extends App.Router
#  routes:
#    'getting_started': Index
#Config.Controller.push App.GetStarted;
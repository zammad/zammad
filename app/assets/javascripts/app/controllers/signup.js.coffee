$ = jQuery.sub()
User = App.User

class Index extends App.Controller
  className: 'container signup'
  
  events:
    'submit form': 'submit',
    'click .submit': 'submit',
    'click .cancel': 'cancel',

  constructor: ->
    super
    
    # set title
    @title 'Sign up'

    @render()
    
    @navupdate '#signup'

    
  render: ->
    
    # set password as required
    for item in User.configure_attributes
      if item.name is 'password'
        item.null = false

    @html App.view('signup')(
      form: @formGen( model: User, required: 'signup' ),
    )

  cancel: ->
    @log 'cancel....'
    @navigate 'login'

  submit: (e) ->
    @log 'submit'
    e.preventDefault()
    @params = @formParam(e.target)
    ###
    for num in [1..199]
      user = new User
      params.login = 'login_c' + num
      user.updateAttributes(params)
    return false
    ###
    
    # if no login is given, use emails as fallback
    if !@params.login && @params.email
      @params.login = @params.email
      
#    role = App.Role.findByAttribute("name", "Customer")
#    @params.role_ids = role.id
#    @params.role_ids = 3
    @params.role_ids = []
    @log 'updateAttributes', @params
    user = new User
    user.load(@params)

    errors = user.validate()
    if errors
      @log 'error new', errors
      @validateForm( form: e.target, errors: errors )
      return false

    # save user
    user.save(
      success: (r) =>
        auth = new App.Auth
        auth.login(
          data: {
            username: @params.login,
            password: @params.password,
          },
          success: @success
          error: @error,
        )
#      error: =>
#        @modalHide()
    )
  
  success: (data, status, xhr) =>
    @log 'login:success', data

    # login check
    auth = new App.Auth
    auth.loginCheck()

    # add notify
    Spine.trigger 'notify:removeall'
    @notify
      type: 'success',
      msg: 'Thanks for joining. Email sent to "' + @params.email + '". Please verify your email address.'
    
    # redirect to #
    @navigate '#'

  error: (xhr, statusText, error) =>
    console.log 'login:error'
    
    # add notify
    Spine.trigger 'notify:removeall'
    Spine.trigger 'notify', {
      type: 'warning',
      msg: 'Wrong Username and Password combination.', 
    }
    
    # rerender login page
    @render(
      msg: 'Wrong Username and Password combination.', 
      username: @username
    )

Config.Routes['signup'] = Index

#class App.SignUp extends App.Router
#  routes:
#    'signup': Index
#Config.Controller.push App.SignUp
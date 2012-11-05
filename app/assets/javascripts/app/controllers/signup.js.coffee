$ = jQuery.sub()

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
    @navupdate '#signup'

    @render()

  render: ->

    # set password as required
    for item in App.User.configure_attributes
      if item.name is 'password'
        item.null = false

    @html App.view('signup')()

    new App.ControllerForm(
      el: @el.find('#form-signup'),
      model: App.User,
      required: 'signup',
      autofocus: true,
    )

  cancel: ->
    @navigate 'login'

  submit: (e) ->
    @log 'submit'
    e.preventDefault()
    @params = @formParam(e.target)

    # if no login is given, use emails as fallback
    if !@params.login && @params.email
      @params.login = @params.email

    @params.role_ids = [0]
    @log 'updateAttributes', @params
    user = new App.User
    user.load(@params)

    errors = user.validate()
    if errors
      @log 'error new', errors
      @formValidate( form: e.target, errors: errors )
      return false

    # save user
    user.save(
      success: (r) =>
        App.Auth.login(
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

    # login check
    App.Auth.loginCheck()

    # add notify
    App.Event.trigger 'notify:removeall'
    @notify
      type: 'success',
      msg: 'Thanks for joining. Email sent to "' + @params.email + '". Please verify your email address.'

    # redirect to #
    @navigate '#'

  error: (xhr, statusText, error) =>

    # add notify
    App.Event.trigger 'notify:removeall'
    App.Event.trigger 'notify', {
      type: 'warning',
      msg: 'Wrong Username and Password combination.', 
    }

    # rerender login page
    @render(
      msg: 'Wrong Username and Password combination.', 
      username: @username
    )

App.Config.set( 'signup', Index, 'Routes' )
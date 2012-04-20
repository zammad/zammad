$ = jQuery.sub()

class Index extends App.Controller
  events:
    'submit #login': 'login',
    'click #register': 'register'
    
  constructor: ->
    super
    @title 'Sign in'
    @render()
    @navupdate '#login'

  render: (data = {}) ->
    auth_provider_all = {
      facebook: {
        url:    '/auth/facebook',
        name:   'Facebook',
        config: 'auth_facebook',
      },
      twitter: {
        url:    '/auth/twitter',
        name:   'Twitter',
        config: 'auth_twitter',
      },
      linkedin: {
        url:    '/auth/linkedin',
        name:   'LinkedIn',
        config: 'auth_linkedin',
      },
      google_oauth2: {
        url:    '/auth/google_oauth2',
        name:   'Google',
        config: 'auth_google_oauth2',
      },
    }
    auth_providers = []
    for key, provider of auth_provider_all
      if Config[provider.config] is true || Config[provider.config] is "true"
        auth_providers.push provider
    
    @html App.view('login')(
      item:           data,
      auth_providers: auth_providers
    )
    if $(@el).find('[name="username"]').val()
      $(@el).find('[name="username"]').focus()
  
  login: (e) ->
    e.preventDefault()
    params = @formParam(e.target)
    
    # session create with login/password
    auth = new App.Auth
    auth.login(
      data:    params,
      success: @success
      error:   @error,
    )
 
  success: (data, status, xhr) =>
    @log 'login:success', data

    # set avatar
    if !data.session.image
      data.session.image = 'http://placehold.it/48x48'

    # update config
    for key, value of data.config
      window.Config[key] = value

    # store user data
    for key, value of data.session
      window.Session[key] = value

    # refresh default collections
    for key, value of data.default_collections
      App[key].refresh( value, options: { clear: true } )

    Spine.trigger 'navrebuild', data.session

    # rebuild navbar with updated ticket count of overviews
    Spine.trigger 'navupdate_remote'

    # add notify
    Spine.trigger 'notify:removeall'
    Spine.trigger 'notify', {
      type: 'success',
      msg: 'Login successfully! Have a nice day!', 
    }

    # redirect to #
    if window.Config['requested_url'] isnt ''
      @navigate window.Config['requested_url']
      
      # reset
      window.Config['requested_url'] = ''
    else
      @navigate '#/'

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

Config.Routes['login'] = Index

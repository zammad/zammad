class Index extends App.ControllerContent
  events:
    'submit #login': 'login'

  constructor: ->
    super

    # redirect to getting started if setup is not done
    if !@Config.get('system_init_done')
      @navigate '#getting_started'
      return

    # navigate to # if session if exists
    if @Session.get()
      @navigate '#'
      return

    @navHide()

    @title 'Sign in'
    @render()
    @navupdate '#login'

    # observe config changes related to login page
    @bind('config_update_local', (data) =>
      return if !data.name.match(/^maintenance/) &&
        !data.name.match(/^auth/) &&
        data.name != 'user_lost_password' &&
        data.name != 'user_create_account' &&
        data.name != 'product_name' &&
        data.name != 'product_logo' &&
        data.name != 'fqdn'
      @render()
      'rerender'
    )

  render: (data = {}) ->
    auth_provider_all = {
      facebook: {
        url:    '/auth/facebook'
        name:   'Facebook'
        config: 'auth_facebook'
        class:  'facebook'
      },
      twitter: {
        url:    '/auth/twitter'
        name:   'Twitter'
        config: 'auth_twitter'
        class:  'twitter'
      },
      linkedin: {
        url:    '/auth/linkedin'
        name:   'LinkedIn'
        config: 'auth_linkedin'
        class:  'linkedin'
      },
      github: {
        url:    '/auth/github'
        name:   'Github'
        config: 'auth_github'
        class:  'github'
      },
      gitlab: {
        url:    '/auth/gitlab'
        name:   'Gitlab'
        config: 'auth_gitlab'
        class:  'gitlab'
      },
      google_oauth2: {
        url:    '/auth/google_oauth2'
        name:   'Google'
        config: 'auth_google_oauth2'
        class:  'google'
      },
    }
    auth_providers = []
    for key, provider of auth_provider_all
      if @Config.get(provider.config) is true || @Config.get(provider.config) is 'true'
        auth_providers.push provider

    @html App.view('login')(
      item:           data
      logoUrl:        @logoUrl()
      auth_providers: auth_providers
    )

    # set focus to username or password
    if !$(@el).find('[name="username"]').val()
      $(@el).find('[name="username"]').focus()
    else
      $(@el).find('[name="password"]').focus()

    # scroll to top
    @scrollTo()

  login: (e) ->
    e.preventDefault()
    e.stopPropagation()

    @formDisable(e)
    params = @formParam(e.target)

    # remember username
    @username = params['username']

    # session create with login/password
    App.Auth.login(
      data:    params
      success: @success
      error:   @error
    )

  success: (data, status, xhr) =>

    # redirect to #
    requested_url = @Config.get('requested_url')
    if requested_url && requested_url isnt '#login' && requested_url isnt '#logout'
      @log 'notice', "REDIRECT to '#{requested_url}'"
      @navigate requested_url

      # reset
      @Config.set('requested_url', '')
    else
      @log 'notice', 'REDIRECT to -#/-'
      @navigate '#/'

  error: (xhr, statusText, error) =>
    detailsRaw = xhr.responseText
    details = {}
    if !_.isEmpty(detailsRaw)
      details = JSON.parse(detailsRaw)

    # add notify
    @notify
      type:      'error'
      msg:       App.i18n.translateContent(details.error || 'Wrong Username and Password combination.')
      removeAll: true

    # rerender login page
    @render(
      username: @username
    )

    # login shake
    @delay(
      => @shake( @el.find('.hero-unit') ),
      600
    )

App.Config.set('login', Index, 'Routes')

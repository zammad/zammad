class Login extends App.ControllerFullPage
  events:
    'submit #login': 'login'
    'click .js-go-to-mobile': 'goToMobile'
    'click .js-try-another':              'clickedTryAnotherTwoFactor'
    'click .js-select-two-factor-method': 'clickedAnotherTwoFactor'
  className: 'login'

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

    # show session timeout message on login screen
    data = {}
    if window.location.hash is '#session_timeout'
      data = {
        errorMessage: App.i18n.translateContent('Due to inactivity, you have been automatically logged out.')
      }
    if window.location.hash is '#session_invalid'
      data = {
        errorMessage: App.i18n.translateContent('The session is no longer valid. Please log in again.')
      }

    @title __('Sign in')

    if !App.Config.get('user_show_password_login') && @password_auth_token
      params =
        token: @password_auth_token
      @ajax(
        id:          'admin_password_auth_verify'
        type:        'POST'
        url:         "#{@apiPath}/users/admin_password_auth_verify"
        data:        JSON.stringify(params)
        processData: true
        success:     (verify_data, status, xhr) =>
          @showAdminPasswordLogin = true
          data.username = verify_data.user_login

          @render(data)
          @navupdate '#login'
        error: =>
          data.showAdminPasswordLoginFailed = true

          @render(data)
          @navupdate '#login'
      )
    else
      @render(data)
      @navupdate '#login'

    # observe config changes related to login page
    @controllerBind('config_update_local', (data) =>
      return if !data.name.match(/^maintenance/) &&
        !data.name.match(/^auth/) &&
        data.name != 'user_lost_password' &&
        data.name != 'user_create_account' &&
        data.name != 'product_name' &&
        data.name != 'product_logo' &&
        data.name != 'fqdn' &&
        data.name != 'user_show_password_login'
      @render()
      'rerender'
    )

    @controllerBind('ui:rerender', =>
      @render()
    )
    @publicLinksSubscribeId = App.PublicLink.subscribe(=>
      @render()
    )

  release: =>
    if @publicLinksSubscribeId
      App.PublicLink.unsubscribe(@publicLinksSubscribeId)

  render: (data = {}) ->
    if @showAdminPasswordLogin
      data.showAdminPasswordLogin = true

    auth_provider_all = App.Config.get('auth_provider_all')
    auth_providers = []
    for key, provider of auth_provider_all
      if @Config.get(provider.config) is true || @Config.get(provider.config) is 'true'
        auth_providers.push provider

    public_links = App.PublicLink.search(
      filter:
        screen: ['login']
      sortBy: 'prio'
    )

    @replaceWith App.view('login')(
      item:             data
      logoUrl:          @logoUrl()
      auth_providers:   auth_providers
      public_links:     public_links
      show_mobile_link: App.MobileDetection.isMobile() or App.MobileDetection.isForcingDesktopView()
    )

    # set focus to username or password
    if !@$('[name="username"]').val()
      @$('[name="username"]').trigger('focus')
    else
      @$('[name="password"]').trigger('focus')

    # scroll to top
    @scrollTo()

  renderTwoFactor: (data = {}) ->
    @twoFactorMethod = data.twoFactorMethod

    method = App.TwoFactorMethods.methodByKey(@twoFactorMethod)

    methodLogin = new App["TwoFactorLoginMethod#{method.identifier}"](
      errorMessage: data.errorMessage
      loginContext: @
      method:       method
    )

    methodLoginElements = methodLogin.render()

    @el.find('.js-form').html   methodLoginElements.form
    @el.find('.js-footer').html methodLoginElements.footer

    # Remove all other elements below the form.
    @el.find('.js-form').nextAll().remove()

    methodLogin.postRender()

  renderTwoFactorMethods: ->
    methodsToShow = _.filter(App.TwoFactorMethods.sortedMethods(),
      (elem) => _.includes(@twoFactorAvailableMethods, elem.key))

    @el.find('.js-form').html App.view('widget/two_factor_login/try_another_method')(
      defaultTwoFactorMethod:    @defaultTwoFactorMethod
      twoFactorMethods:          methodsToShow
      twoFactorHasRecoveryCodes: @twoFactorHasRecoveryCodes
    )

    @el.find('.js-footer').html App.view('widget/two_factor_login/help_text')()

  login: (e) ->
    e.preventDefault()
    e.stopPropagation()

    @formDisable(e)
    params = @formParam(e.target)

    # remember username
    @formPayload = _.pick params, ['username', 'password', 'remember_me']

    # session create with login/password
    App.Auth.login(
      data:    params
      success: @success
      error:   @error
    )

  success: (data, status, xhr) =>

    # redirect to #
    @log 'notice', 'REDIRECT to -#/-'
    @navigate '#/'

  error: (xhr, statusText, error) =>
    detailsRaw = xhr.responseText
    details = {}
    if !_.isEmpty(detailsRaw)
      details = JSON.parse(detailsRaw)

    errorMessage = App.i18n.translateContent(details.error || 'Could not process your request')

    if config = details.two_factor_required
      @defaultTwoFactorMethod          = config.default_two_factor_authentication_method
      @twoFactorAvailableMethods       = config.available_two_factor_authentication_methods
      @twoFactorHasRecoveryCodes       = config.recovery_codes_available
      @twoFactorAvailableAnotherMethod = config.available_two_factor_authentication_methods.length > 1 || (config.recovery_codes_available && config.available_two_factor_authentication_methods.length > 0)



      @renderTwoFactor(
        twoFactorMethod:           @defaultTwoFactorMethod
        twoFactorAvailableMethods: @twoFactorAvailableMethods
      )

      return

    if @twoFactorMethod
      @renderTwoFactor(
        twoFactorMethod: @twoFactorMethod
        errorMessage: errorMessage
      )
    else
      # rerender login page
      @render(
        errorMessage: errorMessage
      )

    # login shake
    @delay(
      => @shake( @$('.hero-unit') )
      600
    )

  clickedTryAnotherTwoFactor: (e) ->
    @preventDefaultAndStopPropagation(e)

    @renderTwoFactorMethods()

  clickedAnotherTwoFactor: (e) ->
    @preventDefaultAndStopPropagation(e)

    newMethod = e.target.dataset['method']

    @renderTwoFactor(
      twoFactorMethod:           newMethod
      twoFactorAvailableMethods: @twoFactorAvailableMethods
    )

  goToMobile: (e) ->
    @preventDefaultAndStopPropagation(e)

    App.MobileDetection.redirectToMobile()

App.Config.set('login', Login, 'Routes')
App.Config.set('login/admin/:password_auth_token', Login, 'Routes')
App.Config.set('session_timeout', Login, 'Routes')
App.Config.set('session_invalid', Login, 'Routes')

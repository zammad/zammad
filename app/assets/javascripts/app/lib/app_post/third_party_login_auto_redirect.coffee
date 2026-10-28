# Keys are shared with the new apps (app/frontend/shared/composables/authentication/useThirdPartyAuthenticationAutoRedirect.ts).
class App.ThirdPartyLoginAutoRedirect
  @PAUSED_KEY: 'third-party-login-auto-redirect-paused'
  @LAST_REDIRECT_KEY: 'third-party-login-auto-redirect-at'

  # A callback which returns to the login page without a session (e.g. maintenance mode) must not loop.
  @LOOP_GUARD_MS: 60000

  # Shared by all tabs, otherwise another open tab would sign the user in again.
  # A full storage must not stop the logout.
  @pause: ->
    try
      localStorage.setItem(@PAUSED_KEY, 'true')
    catch e
      App.Log.error('App.ThirdPartyLoginAutoRedirect', 'Could not pause the automatic redirect.', e)

  @resume: ->
    localStorage.removeItem(@PAUSED_KEY)
    sessionStorage.removeItem(@LAST_REDIRECT_KEY)

  @provider: (authProviders, passwordAuthToken) ->
    return if !App.Config.get('third_party_login_auto_redirect') || App.Config.get('user_show_password_login')
    return if App.Config.get('maintenance_mode') || App.Config.get('import_mode')
    return if authProviders.length isnt 1
    return if passwordAuthToken
    return if localStorage.getItem(@PAUSED_KEY) || @redirectedRecently()

    authProviders[0]

  @redirect: (provider) ->
    sessionStorage.setItem(@LAST_REDIRECT_KEY, String(Date.now()))

    form = $('<form>', method: 'post', action: provider.url)
      .append($('<input>', type: 'hidden', name: 'authenticity_token', value: Spine.Ajax.defaults.headers['X-CSRF-Token']))
      .appendTo('body')

    form.get(0).submit()

  @redirectedRecently: ->
    lastRedirect = Number(sessionStorage.getItem(@LAST_REDIRECT_KEY))

    lastRedirect > 0 && Date.now() - lastRedirect < @LOOP_GUARD_MS

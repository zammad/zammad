class App.DesktopBetaSwitch
  @isSwitchDismissed: ->
    App.LocalStorage.get('beta-ui-switch-dismiss')

  @isSwitchVisible: =>
    return false if not App.Config.get('ui_desktop_beta_switch')

    role_ids = App.Config.get('ui_desktop_beta_switch_role_ids')

    return false if not _.isEmpty(role_ids) and not _.some(role_ids, (role_id) ->
      _.contains(App.User.current().role_ids, parseInt(role_id, 10))
    )

    return false if not App.User.current()?.permission('user_preferences.beta_ui_switch')
    return false if @isSwitchDismissed()

    true

  @isSwitchActive: ->
    App.Config.get('ui_desktop_beta_switch') and App.LocalStorage.get('beta-ui-switch')

  @dismissSwitch: ->
    App.LocalStorage.set('beta-ui-switch-dismiss', true)
    App.Event.trigger('ui:rerender')

    true

  @showSwitch: ->
    if App.LocalStorage.get('beta-ui-switch-dismiss')
      App.LocalStorage.delete('beta-ui-switch-dismiss')

    App.Event.trigger('ui:rerender')

    true

  @activateSwitch: ->
    App.LocalStorage.set('beta-ui-switch', true)

    true

  @navigateToDesktop: ->
    target = '/desktop'

    if window.location.hash
      target += "/#{window.location.hash}"

    window.location.href = target

  @autoRedirectToDesktop: =>
    # Automatically redirect to desktop view, if switch is active for the current user.
    @navigateToDesktop() if @isSwitchActive()

class App.DesktopBetaSwitchPlugin extends App.Controller
  constructor: ->
    super

    App.DesktopBetaSwitch.autoRedirectToDesktop()

App.Config.set('desktop_beta_switch', App.DesktopBetaSwitchPlugin, 'Plugins')

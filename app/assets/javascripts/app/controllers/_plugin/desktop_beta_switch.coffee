class App.DesktopBetaSwitch
  @isSwitchDismissed: ->
    App.LocalStorage.get('beta-ui-switch-dismiss')

  @isSwitchVisible: =>
    App.Config.get('ui_desktop_beta_switch') and App.User.current()?.permission('user_preferences.beta_ui_switch') and not @isSwitchDismissed()

  @isSwitchActive: ->
    App.Config.get('ui_desktop_beta_switch') and App.LocalStorage.get('beta-ui-switch')

  @dismissSwitch: ->
    App.LocalStorage.set('beta-ui-switch-dismiss', true)
    App.Event.trigger('ui:beta:saved')

    true

  @showSwitch: ->
    if App.LocalStorage.get('beta-ui-switch-dismiss')
      App.LocalStorage.delete('beta-ui-switch-dismiss')

    App.Event.trigger('ui:beta:saved')

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

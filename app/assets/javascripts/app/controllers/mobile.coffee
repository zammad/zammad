class Mobile
  constructor: ->
    # TODO: Remove this error notification when the mobile frontend switch is not needed any more.
    if not App.Config.get('mobile_frontend_enabled')
      @notify
        type:    'error'
        msg:     App.i18n.translateContent(__('Mobile frontend is disabled.'))
        timeout: 6000

      return

    @clearForceDesktopApp()
    @navigateToMobile()

  clearForceDesktopApp: ->
    if App.LocalStorage.get('forceDesktopApp', false)
      App.LocalStorage.delete('forceDesktopApp')

  navigateToMobile: ->
    target = '/mobile'

    # Append the previous route to the target URL, if there is a history entry.
    #   Mobile view will handle the internal redirection automatically.
    if window.history?
      history = App.Config.get('History')
      oldLocation = history[history.length-2]

      if oldLocation
        target += "/#{oldLocation}"

        window.history.replaceState(null, null, oldLocation)

    window.location.href = target

App.Config.set('mobile', Mobile, 'Routes')

if isMobile() or App.LocalStorage.get('forceDesktopApp', false)
  # TODO: Remove `mobile_frontend_enabled` check when this switch is not needed any more.
  App.Config.set('Mobile', { prio: 1500, parent: '#current_user', name: __('Continue to mobile'), translate: true, target: '#mobile', setting: ['mobile_frontend_enabled'] }, 'NavBarRight')

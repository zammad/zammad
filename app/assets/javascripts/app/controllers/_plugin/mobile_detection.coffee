class App.MobileDetection
  @isMobile: ->
    isMobile()

  @isForcingDesktopView: ->
    App.LocalStorage.get('forceDesktopApp', false)

  @clearForceDesktopApp: ->
    if App.LocalStorage.get('forceDesktopApp', false)
      App.LocalStorage.delete('forceDesktopApp')

  @navigateToMobile: ->
    target = '/mobile'

    if window.location.hash
      target += "/#{window.location.hash}"

    window.location.href = target

  @redirectToMobile: =>
    @clearForceDesktopApp()
    @navigateToMobile()

  @autoRedirectToMobile: =>
    # Automatically redirect to mobile view, if on mobile device and not forcing desktop view.
    if @isMobile() and !@isForcingDesktopView()
      @redirectToMobile()

class App.MobileDetectionWorker
  clicked: (e) ->
    App.MobileDetection.redirectToMobile()

class App.MobileDetectionPlugin extends App.Controller
  constructor: ->
    super

    App.MobileDetection.autoRedirectToMobile()
    @delay(@launchTaskManagerTask)

  launchTaskManagerTask: ->
    App.TaskManager.execute(
      key:        'MobileDetection'
      controller: 'MobileDetectionWorker'
      params:     {}
      show:       false
      persistent: true
    )

App.Config.set('mobile_detection', App.MobileDetectionPlugin, 'Plugins')

if App.MobileDetection.isMobile() or App.LocalStorage.get('forceDesktopApp', false)
  App.Config.set('Mobile',
    {
      prio: 1500,
      parent: '#current_user',
      name: __('Continue to mobile'),
      translate: true,
      target: '#',
      onclick: true,
      key: 'MobileDetection',
    }
    , 'NavBarRight')

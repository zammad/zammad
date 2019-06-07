class DefaultRouter extends App.Controller

  constructor: ->
    super

    # no default routing on test pages
    if window.location.pathname.substr(0,5) is '/test'
      return

    # check if import is active
    if !@Config.get('system_init_done') && @Config.get('import_mode')
      @navigate '#import', true
      return

    # route to getting started screen
    if !@Config.get('system_init_done')
      @navigate '#getting_started', true
      return

    if @Config.get('default_controller')
      @navigate @Config.get('default_controller'), true
      return

    @navigate '#dashboard', true

App.Config.set('', DefaultRouter, 'Routes')
App.Config.set('/', DefaultRouter, 'Routes')

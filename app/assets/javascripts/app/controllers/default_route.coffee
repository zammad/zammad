class DefaultRouter extends App.Controller

  constructor: ->
    super

    # no default routing on test pages
    if window.location.pathname.substr(0,5) is '/test'
      return

    # check if import is active
    if !@Config.get('system_init_done') && @Config.get('import_mode')
      @navigate '#import', { hideCurrentLocationFromHistory: true }
      return

    # route to getting started screen
    if !@Config.get('system_init_done')
      @navigate '#getting_started', { hideCurrentLocationFromHistory: true }
      return

    # redirect to requested url
    requested_url = @requestedUrlWas()
    if requested_url
      @requestedUrlRemember('')
      @log 'notice', "REDIRECT to '#{requested_url}'"
      @navigate requested_url, { hideCurrentLocationFromHistory: true }
      return

    if @Config.get('default_controller')
      @navigate @Config.get('default_controller'), { hideCurrentLocationFromHistory: true }
      return

    @navigate '#dashboard', { hideCurrentLocationFromHistory: true }

App.Config.set('', DefaultRouter, 'Routes')
App.Config.set('/', DefaultRouter, 'Routes')

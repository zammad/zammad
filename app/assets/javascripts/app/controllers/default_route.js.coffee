class Index extends App.Controller

  constructor: ->
    super

    # no default routing on test pages
    if window.location.pathname.substr(0,5) is '/test'
      return

    # route to getting started screen
    if !@Config.get('system_init_done')
      @navigate '#getting_started'
      return

    # check role
    if @isRole('Customer')
      @navigate '#ticket/view/my_tickets'
      return

    if @Config.get('default_controller')
      @navigate @Config.get('default_controller')
      return

    @navigate '#dashboard'

App.Config.set( '', Index, 'Routes' )
App.Config.set( '/', Index, 'Routes' )

class Index extends App.Controller

  constructor: ->
    super
    
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

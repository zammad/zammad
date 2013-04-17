class Index extends App.ControllerContent
  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    # set title
    @title 'Scheduler'
    @navupdate '#scheduler'

    # render page
    @render()

  render: ->
    
    @html App.view('scheduler')(
      head: 'some header'
    )

App.Config.set( 'scheduler', Index, 'Routes' )

App.Config.set( 'Scheduler', { prio: 3500, parent: '#admin', name: 'Scheduler', target: '#scheduler', role: ['Admin'] }, 'NavBar' )

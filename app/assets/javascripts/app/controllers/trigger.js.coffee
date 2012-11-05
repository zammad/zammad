$ = jQuery.sub()

class Index extends App.Controller
  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    # set title
    @title 'Triggers'
    @navupdate '#trigger'

    # render page
    @render()

  render: ->
    
    @html App.view('trigger')(
      head: 'some header'
    )

App.Config.set( 'trigger', Index, 'Routes' )

App.Config.set( 'Trigger', { prio: 3000, parent: '#admin', name: 'Trigger', target: '#trigger', role: ['Admin'] }, 'NavBar' )
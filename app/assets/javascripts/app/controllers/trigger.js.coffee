class Index extends App.ControllerContent
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

#App.Config.set( 'trigger', Index, 'Routes' )
#App.Config.set( 'Trigger', { prio: 3000, parent: '#admin', name: 'Trigger', target: '#trigger', role: ['Admin'] }, 'NavBar' )

App.Config.set( 'Trigger', { prio: 3000, name: 'Triggers', target: '#manage/triggers', controller: Index, role: ['Admin'] }, 'NavBarLevel2' )


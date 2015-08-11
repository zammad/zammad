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

App.Config.set( 'Trigger', { prio: 3100, name: 'Triggers', parent: '#manage', target: '#manage/triggers', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )
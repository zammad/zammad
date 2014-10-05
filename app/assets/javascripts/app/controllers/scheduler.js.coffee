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

App.Config.set( 'Scheduler', { prio: 2000, name: 'Schedulers', parent: '#manage', target: '#manage/schedulers', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )
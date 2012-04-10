$ = jQuery.sub()

class Index extends App.Controller
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
Config.Routes['scheduler'] = Index


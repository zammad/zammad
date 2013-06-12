class App.Maintenance extends App.ControllerContent
  events:
    'submit form': 'sendMessage'
  constructor: ->
    super
    # render page
    @render()

  render: ->
    
    @html App.view('maintenance')()

  sendMessage: (e) ->
    e.preventDefault()
    params = @formParam(e.target)
    App.Event.trigger(
        'ws:send'
          action: 'broadcast'
          event:  'session:maintenance'
          spool:  false
          data:   {title: params.headerText, message: params.message}
      )


App.Config.set( 'maintenance', App.Maintenance, 'Routes' )
App.Config.set( 'maintenance', { prio: 3600, parent: '#admin', name: 'Maintenance Message', target: '#maintenance', role: ['Admin'] }, 'NavBar' )
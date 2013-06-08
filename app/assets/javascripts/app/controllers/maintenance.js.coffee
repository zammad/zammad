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
    console.log(params)
    App.Event.trigger('session:maintanance', {title: params.HeaderText, message: params.Message})


App.Config.set( 'maintenance', App.Maintenance, 'Routes' )
App.Config.set( 'maintenance', { prio: 3600, parent: '#admin', name: 'Maintenance Message', target: '#maintenance', role: ['Admin'] }, 'NavBar' )
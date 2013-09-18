class Index extends App.ControllerContent
  events:
    'submit form': 'sendMessage'

  constructor: ->
    super
    # check authentication
    return if !@authenticate()
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
          data:   params
    )
    @render()

App.Config.set( 'Maintenance', { prio: 3600, name: 'Maintenance', parent: '#system', target: '#system/maintenance', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )
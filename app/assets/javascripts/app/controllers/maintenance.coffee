class Index extends App.ControllerContent
  events:
    'submit form': 'sendMessage'

  constructor: ->
    super

    # check authentication
    return if !@authenticate(false, 'Admin')

    @title 'Maintenance', true

    @render()

  render: ->
    @html App.view('maintenance')()

  sendMessage: (e) ->
    e.preventDefault()
    params = @formParam(e.target)
    App.Event.trigger(
      'ws:send'
        event: 'broadcast'
        data:
          event: 'session:maintenance'
          data:  params
    )
    @notify
      type:      'success'
      msg:       App.i18n.translateContent('Sent successfully!')
      removeAll: true
    @render()

App.Config.set( 'Maintenance', { prio: 3600, name: 'Maintenance', parent: '#system', target: '#system/maintenance', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )
class App.MaintenanceWidget extends App.Controller
  constructor: ->
    super

    # bind on event to show message
    App.Event.bind 'session:maintenance', (data) =>
      new Message( message: data )

class Message extends App.ControllerModal
  constructor: ->
    super
    @render(@message)

  render: (message = {}) ->
    @html App.view('modal')(
      title:   message.title,
      message: message.message
      detail:  message.detail
      close:   message.close
    )
    @modalShow(
      backdrop: true,
      keyboard: true,
    )

App.Config.set( 'maintenance', App.MaintenanceWidget, 'Widgets' )

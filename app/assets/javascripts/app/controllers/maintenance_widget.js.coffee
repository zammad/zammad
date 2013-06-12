class App.MaintenanceWidget extends App.Controller
  constructor: ->
    super

    # bind on event to show message
    App.Event.bind 'session:maintenance', (data) =>
      console.log('hannes was here')
      new Message(data)


class Message extends App.ControllerModal
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('modal')(
      title:   @title,
      message: @message
      detail:  @detail
      close:   @close
    )
    @modalShow(
      backdrop: true,
      keyboard: true,
    )

App.Config.set( 'maintenance', App.MaintenanceWidget, 'Widgets' )

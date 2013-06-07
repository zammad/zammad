class App.MaintananceWidget extends App.Controller
  constructor: ->
    super

    # bind on event to show message
    App.Event.bind 'session:maintanance', (data) =>
      console.log('hannes was here')


class Message extends App.ControllerModal
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('modal')(
      title:   'Maintanance Message',
      message: @message
      detail:  @detail
      close:   @close
    )
    @modalShow(
      backdrop: false,
      keyboard: false,
    )

App.Config.set( 'maintanance', App.MaintananceWidget, 'Widgets' )

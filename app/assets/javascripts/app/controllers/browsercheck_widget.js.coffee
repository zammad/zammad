class App.BrowsercheckWidget extends App.Controller
  constructor: ->
    super

    # bind on event to show message
    App.Event.bind 'session:browscheckfailed', (data) =>
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
      backdrop: false,
      keyboard: false,
    )

App.Config.set( 'browscheckfailed', App.BrowsercheckWidget, 'Widgets' )

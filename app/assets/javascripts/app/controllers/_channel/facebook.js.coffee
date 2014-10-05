class App.ChannelFacebook extends App.Controller
  constructor: ->
    super

    # render page
    @render()

  render: ->
    
    @html App.view('channel/facebook')(
      head: 'some header'
    )
    

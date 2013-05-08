class App.ChannelFacebook extends App.Controller
  events:
    'click [data-toggle="tabnav"]': 'toggle',
    
  constructor: ->
    super

    # render page
    @render()

  render: ->
    
    @html App.view('channel/facebook')(
      head: 'some header'
    )
    

$ = jQuery.sub()

class App.ChannelChat extends App.Controller
  events:
    'click [data-toggle="tabnav"]': 'toggle',
    
  constructor: ->
    super

    # render page
    @render()

  render: ->
    
    @html App.view('channel/chat')(
      head: 'some header'
    )
    

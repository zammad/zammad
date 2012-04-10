$ = jQuery.sub()

class App.ChannelTwitter extends App.Controller
  events:
    'click [data-toggle="tabnav"]': 'toggle',
    
  constructor: ->
    super

    # render page
    @render()

  render: ->
    
    @html App.view('channel/twitter')(
      head: 'some header'
    )
    

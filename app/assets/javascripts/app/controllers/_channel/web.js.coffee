$ = jQuery.sub()

class App.ChannelWeb extends App.Controller
  events:
    'click [data-toggle="tabnav"]': 'toggle',
    
  constructor: ->
    super

    # render page
    @render()

  render: ->
    
    @html App.view('channel/web')(
      head: 'some header'
    )
    

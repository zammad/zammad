$ = jQuery.sub()

class App.ChannelEmail extends App.Controller
  events:
    'click [data-toggle="tabnav"]': 'toggle',
    
  constructor: ->
    super

    # render page
    @render()

  render: ->
    
    @html App.view('channel/email')(
      head: 'some header'
    )
    

class App.ChannelFacebook extends App.Controller
  constructor: ->
    super

    @title 'Facebook'

    # render page
    @render()

  render: ->

    @html App.view('channel/facebook')(
      head: 'some header'
    )

App.Config.set( 'Facebook', { prio: 6000, name: 'Facebook', parent: '#channels', target: '#channels/facebook', controller: App.ChannelFacebook, role: ['Admin'] }, 'NavBarAdmin' )

class App.ChannelTwitter extends App.Controller
  constructor: ->
    super

    @title 'Twitter'

    # render page
    @render()

  render: ->
    @html App.view('channel/twitter')(
      head: 'some header'
    )

App.Config.set( 'Twitter', { prio: 5000, name: 'Twitter', parent: '#channels', target: '#channels/twitter', controller: App.ChannelTwitter, role: ['Admin'] }, 'NavBarAdmin' )

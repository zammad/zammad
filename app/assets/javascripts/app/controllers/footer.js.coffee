class App.Footer extends App.Controller
  className: 'container'

  constructor: ->
    super
    @render()

    # rebuild ticket overview data
    App.Event.bind 'ui:rerender', =>
      @render()

  render: () ->
    @html App.view('footer')()

App.Config.set( 'zzzfooter', App.Footer, 'Widgets' )

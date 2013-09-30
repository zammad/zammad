class App.Footer extends App.Controller
  constructor: ->
    super
    @render()

    # rebuild ticket overview data
    @bind 'ui:rerender', =>
      @render()

  render: () ->
    @html App.view('footer')()

#App.Config.set( 'footer', App.Footer, 'Footers' )

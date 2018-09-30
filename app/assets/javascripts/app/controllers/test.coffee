class App.TestController1 extends App.Controller
  constructor: ->
    super
    @showState    = false
    @hideState    = false
    @activeState  = false
    @changedState ||= false
    @render()

  meta: ->
    {}

  show: =>
    @showState = true
    @render()

  hide: =>
    @hideState = true
    @render()

  active: (state) =>
    @activeState = state
    @render()

  changed: =>
    @changedState

  render: ->
    @html "<div>some test controller message:'#{@message}',show:'#{@showState}',hide:'#{@hideState}',active:'#{@activeState}'</div>"

  url: ->
    "#/some/url/#{@message}"

class App.ScriptSnipped extends App.Controller
  #events:
  #  'click .js-record': 'show'

  elements:
    '.js-code': 'code'


  constructor: ->
    super
    #@fetch()
    @records = []
    @render()

  render: =>
    @html App.view('widget/script_snipped')(
      records: @records
      description: @description
      style: @style
      content: @content
    )

    @code.each (i, block) ->
      hljs.highlightBlock block
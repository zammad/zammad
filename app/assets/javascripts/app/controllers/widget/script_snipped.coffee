class App.ScriptSnipped extends App.Controller
  elements:
    '.js-code': 'code'

  constructor: ->
    super
    @render()

  render: =>
    @html App.view('widget/script_snipped')(
      header: @header || 'Usage',
      description: @description
      style: @style
      content: @content
    )

    @code.each((i, block) ->
      hljs.highlightBlock block
    )

class App.KnowledgeBaseScheduledWidget extends App.Controller
  className: 'scheduled-widget'

  constructor: ->
    super

    @el.attr('data-state', @state)
    @el.data('date', @getDate())

    @render()

  getDate: ->
    if string = @object["#{@state}_at"]
      new Date(string)

  render: ->
    @html App.view('knowledge_base/scheduled_widget')(
      timestamp: App.i18n.translateTimestamp(@getDate())
      state:     @state
    )

class App.KnowledgeBasePublicMenuManager extends App.Controller
  events:
    'show.bs.tab':    'willShow'
    'click .js-edit': 'edit'

  constructor: ->
    super

    @listenTo App.KnowledgeBaseMenuItem, 'kb_data_change_loaded', =>
      @render()

  willShow: ->
    @render()

  render: ->
    kb = App.KnowledgeBase.find(@knowledge_base_id)

    @html App.view('knowledge_base/public_menu_manager')(
      locations: @locations(),
      locales:   kb.kb_locales()
    )

  locations: ->
    kb = App.KnowledgeBase.find(@knowledge_base_id)

    [
      {
        headline: 'Header menu',
        identifier: 'header',
        color:      kb.color_header
      },
      {
        headline: 'Footer menu',
        identifier: 'footer'
      }
    ]


  edit: (e) =>
    @preventDefaultAndStopPropagation(e)

    identifier = $(e.target).data('target-location')
    location   = _.find @locations(), (elem) -> elem.identifier == identifier

    new App.KnowledgeBasePublicMenuForm(
      location:          location,
      knowledge_base_id: @knowledge_base_id
      container:         @el.closest('.main')
    )

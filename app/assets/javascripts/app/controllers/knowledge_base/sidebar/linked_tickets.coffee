class App.KnowledgeBaseSidebarLinkedTickets extends App.Controller
  @extend App.PopoverProvidable
  @registerPopovers 'Ticket'

  className: 'sidebar-block'

  events:
    'click .js-add': 'clickedAdd'
    'click .js-delete': 'delete'

  constructor: ->
    super

    @render()
    @listenTo @object, 'refresh', @needsUpdate

  needsUpdate: =>
    @render()

  render: ->
    @html App.view('knowledge_base/sidebar/linked_tickets')(
      tickets: @object.translation(@kb_locale.id)?.linked_tickets() || []
    )

    @renderPopovers()

  fetch: =>
    @ajax(
      id:   "links_#{@object.id}_knowledge_base_answer"
      type: 'GET'
      url: @object.generateURL() + '?full=true'
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @render()
    )

  clickedAdd: (e) =>
    e.preventDefault()

    new App.TicketLinkAdd(
      link_object:    'KnowledgeBase::Answer::Translation'
      link_object_id: @object.translation(@kb_locale.id)?.id
      link_types:     [['normal', 'Normal']]
      object:         @object.translation(@kb_locale.id)
      parent:         @
      container:      @el.closest('.content')
    )

  delete: (e) =>
    e.preventDefault()

    data =
      link_type:                $(e.currentTarget).data('link-type')
      link_object_source:       $(e.currentTarget).data('object')
      link_object_source_value: $(e.currentTarget).data('object-id')
      link_object_target:       'KnowledgeBase::Answer::Translation'
      link_object_target_value: @object.translation(@kb_locale.id)?.id

    # get data
    @ajax(
      id:   "links_remove_#{@object.id}_#{@object_type}"
      type: 'DELETE'
      url:  "#{@apiPath}/links/remove"
      data: JSON.stringify(data)
      processData: true
      success: @fetch
    )

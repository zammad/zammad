class App.KnowledgeBaseSidebarLinkedTickets extends App.Controller
  @extend App.PopoverProvidable
  @registerPopovers 'Ticket'

  className: 'sidebar-block sidebar-linked-tickets'

  events:
    'click .js-add': 'clickedAdd'
    'click .js-delete': 'delete'

  constructor: ->
    super

    @fetch()
    @render()
    @listenTo @object, 'refresh', @updateIfNeeded

  updateIfNeeded: =>
    @fetch()

  render: ->
    localTickets = @localLinks?.map (elem) -> App[elem.link_object].find(elem.link_object_value)

    @html App.view('knowledge_base/sidebar/linked_tickets')(
      tickets: localTickets
      editable: true
    )

    @renderPopovers()

  fetch: =>
    @ajax(
      id:   "kb_links_#{@object.id}"
      type: 'GET'
      url:  "#{@apiPath}/links"
      data:
        link_object:       'KnowledgeBase::Answer::Translation'
        link_object_value: @object.translation(@kb_locale.id).id
      processData: true
      success: (data, status, xhr) =>
        @localLinks = data.links
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

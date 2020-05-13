class App.KnowledgeBasePublicMenuForm extends App.ControllerModal
  autoFocusOnFirstInput: false
  includeForm:           true

  constructor: (params) ->
    @formItems = []
    @head = params.location.headline
    super

  formParams: =>
    @formItems.map (elem) -> elem.buildData()

  content: ->
    @formItems = App.KnowledgeBase
      .find(@knowledge_base_id)
      .kb_locales()
      .map (kb_locale) =>
        menu_items = App.KnowledgeBaseMenuItem.using_kb_locale_location(kb_locale, @location.identifier)

        new App.KnowledgeBasePublicMenuFormItem(
          parent: @,
          knowledge_base_id: @knowledge_base_id,
          location: @location.identifier,
          kb_locale: kb_locale,
          menu_items: menu_items
        )

    @formItems.map (elem) -> elem.el

  hasError: ->
    @formItems
      .map (elem) -> elem.hasError()
      .filter((elem) -> elem)
      .pop()

  onSubmit: (e) ->
    @preventDefaultAndStopPropagation(e)

    if error = @hasError()
      @showAlert(error)
      return

    @clearAlerts()
    @formItems.forEach (elem) -> elem.toggleUserInteraction(false)

    kb = App.KnowledgeBase.find(@knowledge_base_id)

    @ajax(
      id:          'update_menu_items'
      type:        'PATCH'
      url:         kb.manageUrl('update_menu_items')
      data:        JSON.stringify(menu_items_sets: @formParams())
      processData: true
      success:     @onSuccess
      error:       @onError
    )

  onSuccess: (data, status, xhr) =>
    for formItem in @formItems
      for menuItem in App.KnowledgeBaseMenuItem.using_kb_locale_location(formItem.kb_locale, formItem.location)
        menuItem.remove(clear: true)

    App.Collection.loadAssets(data.assets)
    App.KnowledgeBaseMenuItem.trigger('kb_data_change_loaded')
    @close()

  onError: (xhr) =>
    @showAlert(xhr.responseJSON?.error_human || 'Couldn\'t save changes')
    @formItems.forEach (elem) -> elem.toggleUserInteraction(true)

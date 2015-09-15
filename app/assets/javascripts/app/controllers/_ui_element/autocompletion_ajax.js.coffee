class App.UiElement.autocompletion_ajax
  @render: (attribute, params = {}) ->
    if params[attribute.name]
      object = App[attribute.relation].find(params[attribute.name])
      valueName = object.displayName()

    # selectable search
    searchableAjaxSelectObject = new App.SearchableAjaxSelect(
      attribute:
        value:       params[attribute.name]
        valueName:   valueName
        name:        attribute.name
        id:          params.organization_id
        placeholder: App.i18n.translateInline('Search...')
        limt:        10
        object:      attribute.relation
    )
    searchableAjaxSelectObject.element()

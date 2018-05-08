class App.UiElement.autocompletion_multiple_ajax
  @render: (attribute, params = {}) ->
    if params[attribute.name]?.length > 0 || attribute.value?.length > 0
      object = App[attribute.relation].find(params[attribute.name][0] || attribute.value[0])
      valueName = object.displayName()

    # selectable search
    searchableAjaxSelectObject = new App.SearchableAjaxSelect(
      attribute:
        value:       params[attribute.name] || attribute.value
        valueName:   valueName
        name:        attribute.name
        id:          attribute.value
        placeholder: App.i18n.translateInline('Search...')
        limit:       40
        object:      attribute.relation
        ajax:        true
    )
    searchableAjaxSelectObject.element()
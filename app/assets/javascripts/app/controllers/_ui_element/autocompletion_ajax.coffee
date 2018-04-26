# coffeelint: disable=camel_case_classes
class App.UiElement.autocompletion_ajax
  @render: (attribute, params = {}) ->
    id = attribute.value
    if attribute.name == 'organization_ids'
      if params[attribute.name]?.length > 0 || attribute.value?.length > 0
        object = App[attribute.relation].find(params[attribute.name] || attribute.value)
        valueName = 'Alternative Organizations'
        id = params.organization_ids[0] || attribute.value
    else
      if params[attribute.name] || attribute.value
        object = App[attribute.relation].find(params[attribute.name] || attribute.value)
        valueName = object.displayName()
        id = params.organization_id || attribute.value

    # selectable search
    searchableAjaxSelectObject = new App.SearchableAjaxSelect(
      attribute:
        value:       params[attribute.name] || attribute.value
        valueName:   valueName
        name:        attribute.name
        id:          params.organization_ids || attribute.value
        placeholder: App.i18n.translateInline('Search...')
        limit:       40
        object:      attribute.relation
        ajax:        true
    )
    searchableAjaxSelectObject.element()

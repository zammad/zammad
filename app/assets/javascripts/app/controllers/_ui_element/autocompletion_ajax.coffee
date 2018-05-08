# coffeelint: disable=camel_case_classes
class App.UiElement.autocompletion_ajax
  @render: (attribute, params = {}) ->

    if params[attribute.name] || attribute.value
      object = App[attribute.relation].find(params[attribute.name] || attribute.value)
      valueName = object.displayName()

    # selectable search
    searchableAjaxSelectObject = new App.SearchableAjaxSelect(
      attribute:
        value:       params[attribute.name] || attribute.value
        valueName:   valueName
        name:        attribute.name
        id:          params.organization_id || attribute.value
        placeholder: App.i18n.translateInline('Search...')
        limit:       40
        object:      attribute.relation
        ajax:        true
    )
    searchableAjaxSelectObject.element()

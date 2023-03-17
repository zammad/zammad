# coffeelint: disable=camel_case_classes
class App.UiElement.autocompletion_ajax_customer_organization
  @render: (attributeConfig, params = {}, form) ->
    attribute = $.extend(true, {}, attributeConfig)

    if params[attribute.name] || attribute.value
      object = App[attribute.relation].find(params[attribute.name] || attribute.value)
      valueName = object.displayName() if object

    # selectable search
    searchableAjaxSelectObject = new App.CustomerOrganizationAjaxSelect(
      delegate:      form
      attribute:
        value:       params[attribute.name] || attribute.value
        valueName:   valueName
        name:        attribute.name
        id:          params.organization_id || attribute.id
        placeholder: App.i18n.translateInline('Search…')
        limit:       40
        relation:    attribute.relation
        ajax:        true
        multiple:    attribute.multiple
    )
    searchableAjaxSelectObject.element()

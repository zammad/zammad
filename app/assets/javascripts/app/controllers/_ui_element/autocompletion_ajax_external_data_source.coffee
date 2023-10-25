# coffeelint: disable=camel_case_classes
class App.UiElement.autocompletion_ajax_external_data_source
  @render: (attributeConfig, params = {}, form) ->
    attribute = $.extend(true, {}, attributeConfig)

    # selectable search
    searchableAjaxSelectObject = new App.ExternalDataSourceAjaxSelect(
      delegate:        form
      attribute:
        value:         params[attribute.name] || attribute.value
        name:          attribute.name
        id:            attribute.id
        placeholder:   App.i18n.translateInline('Search…')
        limit:         40
        relation:      attribute.relation
        ajax:          true
        multiple:      attribute.multiple
        showArrowIcon: true
        attributeName: attribute.attributeName || attribute.name
        objectName:    attribute.objectName || form?.model?.className
    )
    searchableAjaxSelectObject.element()

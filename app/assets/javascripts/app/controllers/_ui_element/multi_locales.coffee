# coffeelint: disable=camel_case_classes
class App.UiElement.multi_locales extends App.UiElement.ApplicationUiElement
  @render: (attribute, params, form) ->
    new App.MultiLocales(attribute: attribute, object: form?.parentController?.object()).el

  @prepareParams: (attribute, dom, params) ->
    if typeof params[attribute.name] == 'string'
      params[attribute.name] = [params[attribute.name]]

    if !Array.isArray params[attribute.name]
      return

    primary_system_locale_id = dom.find("[name=#{attribute.name}_primary_locale_id]:checked").val()

    params["#{attribute.name}_attributes"] = params[attribute.name]
      .filter (elem) -> elem
      .map (system_locale_id) ->
        data = {
          system_locale_id: system_locale_id
          primary:          system_locale_id == primary_system_locale_id
        }

        domRow = dom.find(".js-primary input[value=#{system_locale_id}]").closest('tr')

        if domRow.hasClass('settings-list--deleted')
          data['_destroy'] = '1'

        if (kb_locale_id = domRow.data('kbLocaleId'))
          data['id'] = parseInt(kb_locale_id)

        data

    delete params["#{attribute.name}"]
    delete params["#{attribute.name}_primary_locale_id"]

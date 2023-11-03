class App.FormHandlerAdminJobObjectName
  @run: (params, attribute, attributes, classname, form, ui) ->
    return if attribute.name isnt 'object'

    return if ui.FormHandlerAdminJobObjectNameDone
    ui.FormHandlerAdminJobObjectNameDone = true

    $(form).find('select[name=object]').off('change.object_name').on('change.object_name', (e) ->
      object_name = $(e.target).val()
      for attr in attributes
        continue if attr.name isnt 'condition' and attr.name isnt 'perform'
        attr.object_name = object_name
        newElement = ui.formGenItem(attr, classname, form)
        form.find('div.form-group[data-attribute-name="' + attr.name + '"]').replaceWith(newElement)
    )

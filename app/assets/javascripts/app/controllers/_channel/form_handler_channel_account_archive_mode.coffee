class App.FormHandlerChannelAccountArchiveMode
  @run: (params, attribute, attributes, classname, form, ui) ->
    attributePrefix = ui.attributePrefix || ''
    return if attribute.name isnt "#{attributePrefix}archive"

    return if ui.FormHandlerChannelAccountArchiveModeDone
    ui.FormHandlerChannelAccountArchiveModeDone = true

    archiveField = $(form).find("input[name='#{attributePrefix}archive']")

    toggleCallback = (field) ->
      archive = field.is(':checked')
      for attr in attributes
        continue if attr.name isnt "#{attributePrefix}archive_before" and attr.name isnt "#{attributePrefix}archive_state_id"
        attr.hide = !archive
        attr.null = !archive
        newElement = ui.formGenItem(attr, classname, form)
        form.find('div.form-group[data-attribute-name="' + attr.name + '"]').replaceWith(newElement)

    archiveField
      .off('change.archive_mode')
      .on('change.archive_mode', (e) ->
        toggleCallback($(e.target))
      )

    toggleCallback(archiveField)

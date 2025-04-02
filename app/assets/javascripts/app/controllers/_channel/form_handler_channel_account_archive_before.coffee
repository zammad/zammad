class App.FormHandlerChannelAccountArchiveBefore
  @run: (params, attribute, attributes, classname, form, ui) ->
    attributePrefix = ui.attributePrefix || ''
    return if attribute.name isnt "#{attributePrefix}archive" and attribute.name isnt "#{attributePrefix}archive_before"

    archive = !!(params.options?.archive or params.archive)
    archiveBefore = params.options?.archive_before or params.archive_before

    isAlertVisible = new Date(archiveBefore) > Date.now() if archiveBefore
    isAlertVisible = false if not archive

    setTimeout(->
      $(form).closest('.modal-body,.wizard-body')
        .find('.js-archiveBeforeAlert')
        .toggleClass('hide', not isAlertVisible)
      0
    )

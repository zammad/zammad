class App.FormHandlerChannelAccountMailboxType
  @run: (params, attribute, attributes, classname, form, ui) ->
    return if attribute.name isnt 'mailbox_type'

    return if ui.FormHandlerChannelAccountMailboxTypeDone
    ui.FormHandlerChannelAccountMailboxTypeDone = true

    $(form).find('select[name=mailbox_type]').off('change.mailbox_type').on('change.mailbox_type', (e) ->
      mailbox_type = $(e.target).val()
      for attr in attributes
        continue if attr.name isnt 'shared_mailbox'
        attr.hide = mailbox_type isnt 'shared'
        attr.null = mailbox_type isnt 'shared'
        newElement = ui.formGenItem(attr, classname, form)
        form.find('div.form-group[data-attribute-name="' + attr.name + '"]').replaceWith(newElement)
    )

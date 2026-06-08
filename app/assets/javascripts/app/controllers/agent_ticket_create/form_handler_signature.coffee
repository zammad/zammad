class TicketCreateFormHandlerSignature

  @run: (params, attribute, attributes, classname, form, ui) ->
    return if !attribute
    return if attribute.name isnt 'group_id'

    result = App.SignatureHelper.findForGroup(params['group_id'])

    # check if signature needs to be added
    type = ui.el.closest('.content').find('[name="formSenderType"]').val()
    if result && type is 'email-out'
      currentBody = ui.el.closest('.content').find('[data-name=body]')
      return if _.isEmpty(currentBody)

      # skip re-applying the signature if it is already present (e.g. after autosave restore)
      return if currentBody.find("[data-signature-id=\"#{result.signature.id}\"]").length

      # remove existing signature and re-add it
      # https://github.com/zammad/zammad/issues/2319
      App.SignatureHelper.removeTopLevel(currentBody)

      # Fake a ticket object, if a group is present (#4448).
      signatureFinished = App.SignatureHelper.render(result.signature.body, { group: result.group })

      sigEl = App.SignatureHelper.buildElement(result.signature.id, signatureFinished)
      App.SignatureHelper.appendToBottom(currentBody, sigEl)
      ui.el.closest('.content').find('[data-name=body]').replaceWith(currentBody)

    # remove old signature
    else
      ui.el.closest('.content').find('[data-name="body"]').find('[data-signature=true]').remove()

App.Config.set('200-ticketFormSignature', TicketCreateFormHandlerSignature, 'TicketCreateFormHandler')

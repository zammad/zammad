class TicketCreateFormHanderSignature

  @run: (params, attribute, attributes, classname, form, ui) ->
    return if !attribute
    return if attribute.name isnt 'group_id'
    signature = undefined
    if params['group_id']
      group = App.Group.find(params['group_id'])
      if group && group.signature_id
        signature = App.Signature.find(group.signature_id)

    # check if signature need to be added
    type = ui.el.closest('.content').find('[name="formSenderType"]').val()
    if signature &&  signature.body && type is 'email-out'
      signatureFinished = App.Utils.replaceTags(signature.body, { user: App.Session.get(), config: App.Config.all() })

      currentBody = ui.el.closest('.content').find('[data-name=body]')
      if !_.isEmpty(currentBody)
        if App.Utils.signatureCheck(currentBody.html() || '', signatureFinished)

          # if signature has changed, in case remove old signature
          signature_id = ui.el.closest('.content').find('[data-signature=true]').data('signature-id')
          if signature_id && signature_id.toString() isnt signature.id.toString()

            ui.el.closest('.content').find('[data-signature="true"]').remove()

          if !App.Utils.htmlLastLineEmpty(currentBody)
            currentBody.append('<br><br>')
          signature = $("<div data-signature=\"true\" data-signature-id=\"#{signature.id}\">#{signatureFinished}</div>")
          App.Utils.htmlStrip(signature)
          currentBody.append(signature)
          ui.el.closest('.content').find('[data-name=body]').replaceWith(currentBody)

    # remove old signature
    else
      ui.el.closest('.content').find('[data-name="body"]').find('[data-signature=true]').remove()

App.Config.set('200-ticketFormSignature', TicketCreateFormHanderSignature, 'TicketCreateFormHandler')

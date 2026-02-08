class TicketCreateFormHandlerSignature

  @run: (params, attribute, attributes, classname, form, ui) ->
    return if !attribute
    return if attribute.name isnt 'group_id'
    signature = undefined
    if params['group_id']
      group = App.Group.find(params['group_id'])
      if group && group.signature_id
        signature = App.Signature.find(group.signature_id)

    # check if signature needs to be added
    type = ui.el.closest('.content').find('[name="formSenderType"]').val()
    if signature && signature.active && signature.body && type is 'email-out'
      signatureFinished = App.Utils.replaceTags(signature.body,
        user: App.Session.get()
        config: App.Config.all()

        # Fake a ticket object, if a group is present (#4448).
        ticket:
          group: group
      )

      currentBody = ui.el.closest('.content').find('[data-name=body]')
      if !_.isEmpty(currentBody)
        # Always remove any existing signature first (from old or new editor format)
        # before checking and potentially adding a new one
        ui.el.closest('.content').find('[data-signature="true"]').remove()

        # Refresh currentBody reference after removal
        currentBody = ui.el.closest('.content').find('[data-name=body]')
        
        if App.Utils.signatureCheck(currentBody.html() || '', signatureFinished)
          signature = $("<div data-signature=\"true\" data-signature-id=\"#{signature.id}\">#{signatureFinished}</div>")
          App.Utils.htmlStrip(signature)
          currentBody.append(signature)
          ui.el.closest('.content').find('[data-name=body]').replaceWith(currentBody)

    # remove old signature
    else
      ui.el.closest('.content').find('[data-name="body"]').find('[data-signature=true]').remove()

App.Config.set('200-ticketFormSignature', TicketCreateFormHandlerSignature, 'TicketCreateFormHandler')

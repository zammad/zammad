# Common event handlers for destination group email address field.
App.DestinationGroupEmailAddressesMixin =
  destinationGroupEmailAddressFormHandler: (item) ->
    formHandler = (params, attribute, attributes, classname, form, ui) =>
      return if attribute.name isnt 'group_id'

      return if ui.FormHandlerGroupEmailAddressDone
      ui.FormHandlerGroupEmailAddressDone = true

      $(form).find('[name=group_id]').off('change.group_id').on('change.group_id', (e) =>
        group_id = $(e.target).val()
        for attr in attributes
          continue if attr.name isnt 'group_email_address_id'
          attr.options = @emailAddressOptions(item?.id, group_id)
          newElement = ui.formGenItem(attr, classname, form)
          form.find('div.form-group[data-attribute-name="' + attr.name + '"]').replaceWith(newElement)
      )

    formHandler

  emailAddressOptions: (id, group_id) ->
    group = App.Group.find(group_id)

    if !id
      return {
        false: App.i18n.translatePlain('Do not change email address (%s)', group?.email_address?.email or '-')
        true: App.i18n.translatePlain('Change to channel email address')
      }

    emailAddresses = App.EmailAddress.findAllByAttribute('channel_id', id)

    _.reduce(
      emailAddresses,
      (acc, emailAddress) ->
        return acc if emailAddress.id is group?.email_address_id
        acc[emailAddress.id] = App.i18n.translatePlain('Change to %s', emailAddress.email)
        acc
      { false: App.i18n.translatePlain('Do not change email address (%s)', group?.email_address?.email or '-') }
    )

  processDestinationGroupEmailAddressParams: (params) ->
    return if _.isUndefined(params.group_email_address_id)
    params.group_email_address = params.group_email_address_id isnt 'false'

    return if params.group_email_address and params.group_email_address_id isnt 'true'
    delete params.group_email_address_id

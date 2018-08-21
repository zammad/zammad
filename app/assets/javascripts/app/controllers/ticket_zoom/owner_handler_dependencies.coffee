class OwnerFormHandlerDependencies

  # central method, is getting called on every ticket form change
  @run: (params, attribute, attributes, classname, form, ui) ->
    return if 'group_id' not of params
    return if 'owner_id' not of params

    owner_attribute = _.find(attributes, (o) -> o.name == 'owner_id')
    return if !owner_attribute
    return if 'alternative_user_options' not of owner_attribute

    # fetch contents using User relation if a Group has been selected, otherwise render alternative_user_options
    if params.group_id
      owner_attribute.relation = 'User'
      delete owner_attribute['options']
    else
      owner_attribute.options = owner_attribute.alternative_user_options
      delete owner_attribute['relation']

    # replace new option list
    owner_attribute.default = params[owner_attribute.name]
    owner_attribute.newValue = params[owner_attribute.name]
    newElement = ui.formGenItem(owner_attribute, classname, form)
    form.find('select[name="owner_id"]').closest('.form-group').replaceWith(newElement)

App.Config.set('150-ticketFormChanges', OwnerFormHandlerDependencies, 'TicketZoomFormHandler')

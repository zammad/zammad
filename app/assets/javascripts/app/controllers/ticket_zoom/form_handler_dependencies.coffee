class TicketZoomFormHandlerDependencies

  # central method, is getting called on every ticket form change
  @run: (params, attribute, attributes, classname, form, ui) ->
    return if !ui.formMeta
    return if !ui.formMeta.dependencies
    return if !ui.formMeta.dependencies[attribute.name]
    dependency = ui.formMeta.dependencies[attribute.name][ parseInt(params[attribute.name]) ]
    if !dependency
      dependency = ui.formMeta.dependencies[attribute.name][ params[attribute.name] ]
    if dependency
      for fieldNameToChange of dependency
        filter = []
        if dependency[fieldNameToChange]
          filter = dependency[fieldNameToChange]

        # find element to replace
        for item in attributes
          if item.name is fieldNameToChange
            item['filter'] = {}
            item['filter'][ fieldNameToChange ] = filter
            item.default = params[item.name]
            item.newValue = params[item.name]
            #if !item.default
            #  delete item['default']
            newElement = ui.formGenItem(item, classname, form)

        # replace new option list
        if newElement
          form.find('[name="' + fieldNameToChange + '"]').closest('.form-group').replaceWith(newElement)

App.Config.set('100-ticketFormChanges', TicketZoomFormHandlerDependencies, 'TicketZoomFormHandler')
App.Config.set('100-ticketFormChanges', TicketZoomFormHandlerDependencies, 'TicketCreateFormHandler')

class TicketZoomFormHandleSecurityOptions

  # central method, is getting called on every ticket form change
  # but only trigger event for group_id changes
  @run: (params, attribute, attributes, classname, form, ui) ->

    return if attribute.name isnt 'group_id'
    App.Event.trigger('ui::ticket::updateSecurityOptions', { taskKey: ui.taskKey })

App.Config.set('140-ticketFormSecurityOptions', TicketZoomFormHandleSecurityOptions, 'TicketZoomFormHandler')

class TicketFormHandlerTextTools

  # central method, is getting called on every ticket form change
  # but only trigger event for group_id changes
  @run: (params, attribute, attributes, classname, form, ui) ->

    return if attribute.name isnt 'group_id'

    App.Event.trigger('TextToolsPreconditionUpdate', { taskKey: ui.taskKey, params: params })

App.Config.set('160-ticketFormTextTools', TicketFormHandlerTextTools, 'TicketZoomFormHandler')
App.Config.set('160-ticketFormTextTools', TicketFormHandlerTextTools, 'TicketCreateFormHandler')

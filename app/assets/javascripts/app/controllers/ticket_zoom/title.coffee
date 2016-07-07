class App.TicketZoomTitle extends App.ObserverController
  model: 'Ticket'
  template: 'ticket_zoom/title'
  observe:
    title: true
  globalRerender: false

  events:
    'blur .js-objectTitle': 'update'

  renderPost: (object) =>
    @$('.js-objectTitle').ce({
      mode:      'textonly'
      multiline: false
      maxlength: 250
    })

  update: (e) =>
    title = $(e.target).ceg() || ''

    # update title
    return if title is @lastAttributres.title
    ticket = App.Ticket.find(@object_id)
    ticket.title = title

    # reset article - should not be resubmited on next ticket update
    ticket.article = undefined

    ticket.save()

    App.TaskManager.mute(@task_key)

    # update taskbar with new meta data
    App.TaskManager.touch(@task_key)

    App.Event.trigger('overview:fetch')

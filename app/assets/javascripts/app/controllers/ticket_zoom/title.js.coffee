class App.TicketZoomTitle extends App.Controller
  events:
    'blur .ticket-title-update': 'update'

  constructor: ->
    super

    @ticket      = App.Ticket.fullLocal( @ticket.id )
    @subscribeId = @ticket.subscribe(@render)
    @render(@ticket)

  render: (ticket) =>

    # check if render is needed
    if @lastTitle && @lastTitle is ticket.title
      return
    @lastTitle = ticket.title

    @html App.view('ticket_zoom/title')(
      ticket: ticket
    )

    @$('.ticket-title-update').ce({
      mode:      'textonly'
      multiline: false
      maxlength: 250
    })

  update: (e) =>
    title = $(e.target).ceg() || ''

    # update title
    if title isnt @ticket.title
      @ticket.title = title

      # reset article - should not be resubmited on next ticket update
      @ticket.article = undefined

      @ticket.save()

      App.TaskManager.mute( @task_key )

      # update taskbar with new meta data
      App.Event.trigger 'task:render'

  release: =>
    App.Ticket.unsubscribe( @subscribeId )
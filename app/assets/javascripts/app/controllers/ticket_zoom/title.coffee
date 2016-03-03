class App.TicketZoomTitle extends App.Controller
  events:
    'blur .ticket-title-update': 'update'

  constructor: ->
    super
    @render()

    # rerender, e. g. on language change
    @bind('ui:rerender', =>
      @render()
    )

  render: (ticket) =>
    if !ticket
      ticket = App.Ticket.fullLocal(@ticket.id)

    if !@subscribeId
      @subscribeId = @ticket.subscribe(@render)

    @title = ticket.title

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
    if title isnt @title
      ticket = App.Ticket.find(@ticket.id)
      ticket.title = title

      # reset article - should not be resubmited on next ticket update
      ticket.article = undefined

      ticket.save()

      App.TaskManager.mute(@task_key)

      # update taskbar with new meta data
      @metaTaskUpdate()

      App.Event.trigger('overview:fetch')

  release: =>
    App.Ticket.unsubscribe(@subscribeId)

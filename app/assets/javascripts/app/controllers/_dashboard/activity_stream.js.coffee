$ = jQuery.sub()

class App.DashboardActivityStream extends App.Controller
  events:
    'click [data-type=edit]': 'zoom'

  constructor: ->
    super
#    @log 'aaaa', @el
    
    @items = []
    
    # get data
    @ajax = new App.Ajax
    @ajax.ajax(
      type:  'GET',
      url:   '/activity_stream',
      data:  {
        limit: @limit,
      }
      processData: true,
#      data: JSON.stringify( view: @view ),
      success: (data, status, xhr) =>
        @items = data.activity_stream

        # load user collection
        @loadCollection( type: 'User', data: data.users )

        # load ticket collection
        @loadCollection( type: 'Ticket', data: data.tickets )

        @render()
    )

    
  render: ->

    # load user data
    for item in @items
      item.created_by = App.User.find(item.created_by_id)
  
    # load ticket data
    for item in @items
      item.ticket = App.Ticket.find(item.o_id)
  
    html = App.view('dashboard/activity_stream')(
      head: 'Activity Stream',
      items: @items
    )
    html = $(html)
    
    @html html

    # start user popups
    @userPopups('left')

  zoom: (e) =>
    e.preventDefault()
    id = $(e.target).parents('[data-id]').data('id')
    @log 'goto zoom!'
    @navigate 'ticket/zoom/' + id

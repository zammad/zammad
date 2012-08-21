$ = jQuery.sub()

class App.LinkInfo extends App.Controller
  events:
    'focusout [data-type=edit]': 'update',

  constructor: ->
    super

    # fetch item on demand
    # get data
    App.Com.ajax(
      id:    'links_' + @object_id + '_' + @object,
      type:  'GET',
      url:   '/links',
      data:  {
        link_object:       @object_type,
        link_object_value: @object.id,
      }
      processData: true,
      success: (data, status, xhr) =>
        @links = data.links

        # load user collection
        @loadCollection( type: 'User', data: data.users )

        # load ticket collection
        @loadCollection( type: 'Ticket', data: data.tickets )

        @render()
    )

  render: () ->

    list = {}
    for item in @links
      if !list[ item['link_type'] ]
        list[ item['link_type'] ] = []
        
      if item['link_object'] is 'Ticket'
        list[ item['link_type'] ].push App.Ticket.find( item['link_object_value'] )

    return if _.isEmpty( @links )

    # insert data
    @html App.view('link_info')(
      links: list,
    )
    
#    @ticketPopups(
#      selector: '.user-tickets',
#      user_id:  user_id,
#    )

  update: (e) =>
    
    # update changes
    note = $(e.target).parent().find('[data-type=edit]').val()
    user = App.User.find(@user_id)
    if user.note isnt note
      user.updateAttributes( note: note )
      @log 'update', e, note, user

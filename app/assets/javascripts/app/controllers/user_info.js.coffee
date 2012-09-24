$ = jQuery.sub()

class App.UserInfo extends App.Controller
  events:
    'focusout [data-type=edit]': 'update',

  constructor: ->
    super
    App.Collection.find( 'User', @user_id, @render )

  render: (user) =>

    # get display data
    data = []
    for item in App.User.configure_attributes
      if item.name isnt 'firstname' && item.name isnt 'lastname'
        if item.info
          data.push item

    # insert data
    @html App.view('user_info')(
      user: user,
      data: data,
    )

    @userTicketPopups(
      selector: '.user-tickets',
      user_id:  user.id,
    )

  update: (e) =>

    # update changes
    note = $(e.target).parent().find('[data-type=edit]').val()
    user = App.Collection.find( 'User', @user_id )
    if user.note isnt note
      user.updateAttributes( note: note )
      @log 'update', e, note, user

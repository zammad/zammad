$ = jQuery.sub()

class App.UserInfo extends App.Controller
  events:
    'focusout [data-type=edit]': 'update',

  constructor: ->
    super

    # fetch item on demand
    fetch_needed = 1
    if App.User.exists(@user_id)
      @log 'exists.user...', @user_id
      fetch_needed = 0
      @render(@user_id)

    if fetch_needed
      @reload(@user_id)

  reload: (user_id) =>
      App.User.bind 'refresh', =>
        @log 'loading.user...', user_id
        App.User.unbind 'refresh'
        @render(user_id)
      App.User.fetch( id: user_id )
    
  render: (user_id) ->

    # load user collection
    user = App.User.find(user_id)
    @loadCollection( type: 'User', data: { new: user }, collection: true )

    # get display data
    data = []
    for item in App.User.configure_attributes
      if item.name isnt 'firstname' && item.name isnt 'lastname'
        if item.info
          data.push item

    # insert data
    @html App.view('user_info')(
      user: App.User.find(user_id),
      data: data,
    )

    @userTicketPopups(
      selector: '.user-tickets',
      user_id:  user_id,
    )

  update: (e) =>

    # update changes
    note = $(e.target).parent().find('[data-type=edit]').val()
    user = App.User.find(@user_id)
    if user.note isnt note
      user.updateAttributes( note: note )
      @log 'update', e, note, user

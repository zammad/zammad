$ = jQuery.sub()

class App.UserInfo extends App.Controller
  events:
    'focusout [data-type=edit]': 'update',

  constructor: ->
    super

    # fetch item on demand
    fetch_needed = 1
    if App.User.exists(@user_id)
      @user = App.User.find(@user_id)
      @log 'exists', @user
      fetch_needed = 0
      @render()

    if fetch_needed
      @reload(@user_id)

  reload: (user_id) =>
      App.User.bind 'refresh', =>
        @log 'loading....', user_id
        @user = App.User.find(user_id)
        @render()
        App.User.unbind 'refresh'
      App.User.fetch( id: user_id )
    
  render: ->

    # define links to linked accounts
    if @user['accounts']
      for account of @user['accounts']
        if account == 'twitter'
          @user['accounts'][account]['link'] = 'http://twitter.com/' + @user['accounts'][account]['username']
        if account == 'facebook'
          @user['accounts'][account]['link'] = 'https://www.facebook.com/profile.php?id=' + @user['accounts'][account]['uid']

    # set default image url
    if !@user.image
      @user.image = 'http://placehold.it/48x48'

    # get display data
    data = []
    for item in App.User.configure_attributes
      if item.name isnt 'firstname'
        if item.name isnt 'lastname'
          if item.info #&& ( @user[item.name] || item.name isnt 'note' )
            data.push item

    # insert data
    @html App.view('user_info')(
      user: @user,
      data: data,
    )
    
    @userTicketPopups(
      selector: '.user-tickets',
      user_id:  @user.id,
    )

  update: (e) =>
    
    # update changes
    note = $(e.target).parent().find('[data-type=edit]').val()
    if @user.note isnt note
      @user.updateAttributes( note: note )
      @log 'update', e, note, @user

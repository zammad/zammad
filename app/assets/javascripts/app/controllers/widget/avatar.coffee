class App.WidgetAvatar extends App.Controller
  constructor: ->
    super

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = App.User.full(@user_id, @render, false, true)

  release: =>
    App.User.unsubscribe(@subscribeId)

  render: (user) =>
    @html user.avatar @size, @position, undefined, false, false, @type

    # start user popups
    @userPopups(@position)

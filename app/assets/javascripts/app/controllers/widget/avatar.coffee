class App.WidgetAvatar extends App.ObserverController
  model: 'User'
  observe:
    login: true
    firstname: true
    lastname: true
    email: true
    image: true
  globalRerender: false

  render: (user) =>
    @html(user.avatar @size, @position, undefined, false, false, @type)
    @userPopups(@position)

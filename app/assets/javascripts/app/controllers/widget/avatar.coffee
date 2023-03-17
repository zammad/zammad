class App.WidgetAvatar extends App.ControllerObserver
  @extend App.PopoverProvidable
  @registerPopovers 'User'

  model: 'User'
  observe:
    login: true
    firstname: true
    lastname: true
    email: true
    image: true
    vip: true
    out_of_office: true,
    out_of_office_start_at: true,
    out_of_office_end_at: true,
    out_of_office_replacement_id: true,
    active: true

  globalRerender: false

  render: (user) =>
    @html(user.avatar(@size, @position, @cssClass, false, false, @type))
    @renderPopovers()

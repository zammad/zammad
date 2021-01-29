class App.ControllerAppContent extends App.Controller
  constructor: (params) ->
    if @requiredPermission
      @permissionCheckRedirect(@requiredPermission)

    # hide tasks
    App.TaskManager.hideAll()

    params.el = params.appEl.find('#content')
    params.el.removeClass('hide').removeClass('active')
    if !params.el.get(0)
      params.appEl.append('<div id="content" class="content flex horizontal"></div>')
      params.el = $('#content')

    super(params)

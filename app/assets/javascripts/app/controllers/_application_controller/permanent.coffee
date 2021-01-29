class App.ControllerPermanent extends App.Controller
  constructor: ->
    if @requiredPermission
      @permissionCheckRedirect(@requiredPermission, true)
    super
class App.ControllerPermanent extends App.Controller
  constructor: ->
    if @constructor.requiredPermission
      @permissionCheckRedirect(@constructor.requiredPermission, true)
    super

class App.ControllerSubContent extends App.Controller
  constructor: ->
    if @requiredPermission
      @permissionCheckRedirect(@requiredPermission)

    super

  show: =>
    if @genericController && @genericController.show
      @genericController.show()
    return if !@header
    @title @header, true

  hide: =>
    if @genericController && @genericController.hide
      @genericController.hide()
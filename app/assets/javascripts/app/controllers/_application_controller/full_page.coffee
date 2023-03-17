class App.ControllerFullPage extends App.Controller
  constructor: (params) ->
    if @requiredPermission
      @permissionCheckRedirect(@requiredPermission)
    super

  replaceWith: (localElement) =>
    @appEl.find('>').not(".#{@className}").remove() if @className
    @appEl.find('>').filter(".#{@className}").remove() if @forceRender
    @el = $(localElement)
    container = @appEl.find('>').filter(".#{@className}")
    if !container.get(0)
      @el.addClass(@className)
      @appEl.append(@el)
      @delegateEvents(@events)
      @refreshElements()
      @el.on('remove', @releaseController)
      @el.on('remove', @release)
    else
      container.html(@el.children())

class App.ControllerFullPage extends App.Controller
  constructor: (params) ->
    if @constructor.requiredPermission
      @permissionCheckRedirect(@constructor.requiredPermission)
    super

  replaceWith: (localElement) =>
    @appEl.find('>').not(".#{@className}").remove() if @className
    @appEl.find('>').filter(".#{@className}").remove() if @forceRender
    container = @appEl.find('>').filter(".#{@className}")

    if container.get(0)
      @el = container
      return container.html($(localElement).children())

    @el = $(localElement)
    @el.addClass(@className)
    @appEl.append(@el)
    @delegateEvents(@events)
    @refreshElements()
    @el.on('remove', @releaseController)
    @el.on('remove', @release)

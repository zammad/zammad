# coffeelint: disable=no_this
Spine = @Spine or require('spine')
$     = Spine.$


class Spine.Manager extends Spine.Module
  @include Spine.Events

  constructor: ->
    @controllers = []
    @bind 'change', @change
    @add(arguments...)

  add: (controllers...) ->
    @addOne(cont) for cont in controllers

  addOne: (controller) ->
    controller.bind 'active', (args...) =>
      @trigger('change', controller, args...)
    controller.bind 'release', =>
      @controllers = (c for c in @controllers when c isnt controller)

    @controllers.push(controller)

  deactivate: ->
    @trigger('change', false, arguments...)

  # Private

  change: (current, args...) ->
    for cont in @controllers when cont isnt current
      cont.deactivate(args...)

    current.activate(args...) if current


Spine.Controller.include
  active: (args...) ->
    if typeof args[0] is 'function'
      @bind('active', args[0])
    else
      args.unshift('active')
      @trigger(args...)
    @

  isActive: ->
    @el.hasClass('active')

  activate: ->
    @el.addClass('active')
    this

  deactivate: ->
    @el.removeClass('active')
    this


class Spine.Stack extends Spine.Controller
  controllers: {}
  routes: {}

  className: 'spine stack'

  constructor: ->
    super

    @manager = new Spine.Manager
    @router  = Spine.Route?.create()

    for key, value of @controllers
      throw Error "'@#{ key }' already assigned" if @[key]?
      @[key] = new value(stack: this)
      @add(@[key])

    for key, value of @routes
      do (key, value) =>
        callback = value if typeof value is 'function'
        callback or= => @[value].active(arguments...)
        @route(key, callback)

    @[@default].active() if @default

  add: (controller) ->
    @manager.add(controller)
    @append(controller)

  release: =>
    @router?.destroy()
    super


module?.exports       = Spine.Manager
module?.exports.Stack = Spine.Stack

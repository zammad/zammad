class App.clickCatcher extends Spine.Controller
  # clickCatcher has no template because it's a plain <div>
  className: 'clickCatcher'

  constructor: (holder, callback, zIndexScale) ->
    super
    @render() if @callback and @holder

  triggerCallback: (event) =>
    event.stopPropagation()
    @callback()
    @remove()
  
  render: ->
    @el.addClass("zIndex-#{ @zIndexScale }") if @zIndexScale
    @el.on('click', @triggerCallback)
    @el.appendTo(@holder)

  remove: ->
    @el.remove()
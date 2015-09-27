class App.ClickCatcher extends Spine.Controller
  # clickCatcher has no template because it's a plain <div>
  className: 'clickCatcher'

  constructor: ->
    super
    @render() if @callback and @holder

  triggerCallback: (e) =>
    e.stopPropagation()
    @callback()
    @remove()

  render: ->
    @el.addClass("zIndex-#{ @zIndexScale }") if @zIndexScale
    @el.on('click', @triggerCallback)
    @el.height(@holder.prop('scrollHeight'))
    @el.appendTo(@holder)

  remove: ->
    @el.remove()
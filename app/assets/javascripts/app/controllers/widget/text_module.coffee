class App.WidgetTextModule extends App.Controller
  constructor: ->
    super

    if !@data
      @data = {}

    # remember instances
    @bindElements = []
    if @selector
      @bindElements = @$(@selector).textmodule()
    else
      if @el.attr('contenteditable')
        @bindElements = @el.textmodule()
      else
        @bindElements = @$('[contenteditable]').textmodule()
    @update()

    @subscribeId = App.TextModule.subscribe(@update, initFetch: true)

  release: =>
    App.TextModule.unsubscribe(@subscribeId)

  reload: (data) =>
    return if !data
    @data = data
    @update()

  update: =>
    allRaw = App.TextModule.all()
    all = []
    for item in allRaw
      if item.active is true
        attributes = item.attributes()
        attributes.content = App.Utils.replaceTags(attributes.content, @data)
        all.push attributes

    # set new data
    if @bindElements[0]
      for element in @bindElements
        if $(element).data().plugin_textmodule
          $(element).data().plugin_textmodule.collection = all

class App.WidgetTextModule extends App.Controller
  constructor: ->
    super

    # remember instances
    @bindElements = []
    if @selector
      @bindElements = @$( @selector ).textmodule()
    else
      if @el.attr('contenteditable')
        @bindElements = @el.textmodule()
      else
        @bindElements = @$('[contenteditable]').textmodule()
    @update()

    @subscribeId = App.TextModule.subscribe(@update, initFetch: true )

  release: =>
    App.TextModule.unsubscribe(@subscribeId)

  reload: (data) =>
    return if !data
    @data = data
    @update()

  update: =>
    allRaw = App.TextModule.all()
    all = []
    data = @data || @
    for item in allRaw
      if item.active is true
        attributes = item.attributes()
        attributes.content = attributes.content.replace( /#\{{0,2}(.+?)\s{0,2}\}/g, ( index, key ) ->
          key = key.replace( /@/g, 'data.' )
          varString = "#{key}" + ''
          #console.log( "tag replacement env: ", data)
          try
            #console.log( "tag replacement: " + key, varString )
            key = eval (varString)
          catch error
            #console.log( "tag replacement error: " + error )
            key = ''
          return key
        )
        all.push attributes

    # set new data
    if @bindElements[0]
      for element in @bindElements
        if $(element).data().plugin_textmodule
          $(element).data().plugin_textmodule.collection = all

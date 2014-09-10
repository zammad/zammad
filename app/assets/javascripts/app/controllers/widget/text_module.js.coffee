class App.WidgetTextModule extends App.Controller
  constructor: ->
    super

    @lastData = {}
    customItemTemplate = "<div><span />&nbsp;<small /></div>"
    elementFactory = (element, e) ->
      template = $(customItemTemplate).find('span')
                          .text(e.val).end()
                          .find('small')
                          .text("(" + e.keywords + ")").end()
      element.append(template)

    @el.parent().find('textarea').sew(
      values:         @reload(@data)
      token:          '::'
      elementFactory: elementFactory
    )

    @subscribeId = App.TextModule.subscribe(@update, initFetch: true )

  release: =>
    App.TextModule.unsubscribe(@subscribeId)

  reload: (data = false) =>
    if data
      @lastData['data'] = data
    @update()

  update: =>
    all = App.TextModule.all()
    values = [{val: '-', keywords: '-'}]
    ui = @lastData || @
    for item in all
      if item.active is true
        contentNew = item.content.replace( /<%=\s{0,2}(.+?)\s{0,2}%>/g, ( all, key ) ->
          key = key.replace( /@/g, 'ui.data.' )
          varString = "#{key}" + ''
#          console.log( "tag replacement env: ", ui.data)
          try
#            console.log( "tag replacement: " + key, varString )
            key = eval (varString)
          catch error
#            console.log( "tag replacement error: " + error )
            key = ''
          return key
        )
        value = { val: contentNew, keywords: item.keywords || item.name }
        values.push value

    if values.length isnt 1
      values.shift()

    # set new data
    if @el[0]
      if $(@el[0]).data()
        if $(@el[0]).data().plugin_sew
          $(@el[0]).data().plugin_sew.options.values = values

    return values

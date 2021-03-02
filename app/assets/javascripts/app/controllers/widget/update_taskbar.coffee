class App.UpdateTastbar extends App.Controller
  constructor: ->
    super

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = @genericObject.subscribe(@update)

  release: =>
    App[@genericObject.constructor.className].unsubscribe(@subscribeId)

  update: (genericObject) =>

    # update taskbar with new meta data
    App.TaskManager.touch(@taskKey)
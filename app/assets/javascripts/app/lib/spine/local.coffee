Spine = @Spine or require('spine')

Spine.Model.Local =
  extended: ->
    testLocalStorage = 'spine' + new Date().getTime()
    try
      localStorage.setItem(testLocalStorage, testLocalStorage)
      localStorage.removeItem(testLocalStorage)
    catch e
      return

    @change @saveLocal
    @fetch @loadLocal

  saveLocal: ->
    result = JSON.stringify(@)
    localStorage[@className] = result

  loadLocal: (options = {})->
    options.clear = true unless options.hasOwnProperty('clear')
    result = localStorage[@className]
    @refresh(result or [], options)

module?.exports = Spine.Model.Local

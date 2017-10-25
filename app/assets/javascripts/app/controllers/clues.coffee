class Index extends App.Controller
  constructor: ->
    super
    @navupdate '#', true
    @clues()

  clues: =>
    new App.FirstStepsClues(
      el: @el
      onComplete: =>
        App.Ajax.request(
          id:          'preferences'
          type:        'PUT'
          url:         "#{@apiPath}/users/preferences"
          data:        JSON.stringify(intro: true)
          processData: true
        )
        @navigate '#'
    )

App.Config.set('clues', Index, 'Routes')

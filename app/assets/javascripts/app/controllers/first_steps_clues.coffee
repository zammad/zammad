class FirstStepsClues extends App.Controller
  constructor: ->
    super
    @navupdate '#', true
    @clues()

  clues: =>
    new App.FirstStepsClues(
      appEl: @appEl
      onComplete: =>
        App.Ajax.request(
          id:          'preferences'
          type:        'PUT'
          url:         "#{@apiPath}/users/preferences"

          # Initial clue is special in that sense that once completed,
          #   it will prevent further clues from being shown to the same user.
          data: JSON.stringify(
            intro: true
            keyboard_shortcuts_clues: true
          )
          processData: true
        )
        @navigate '#'
    )

App.Config.set('clues', FirstStepsClues, 'Routes')

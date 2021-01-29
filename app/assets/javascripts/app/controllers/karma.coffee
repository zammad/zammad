class KarmaContent extends App.Controller
  constructor: ->
    new Karma()

class Karma extends App.ControllerModal
  head: 'Zammad Karma'
  buttonSubmit: false
  buttonCancel: true
  shown: false
  #events:
  #  'click .js-check': 'done'

  constructor: ->
    super
    @load()

    # rerender view, e. g. on langauge change
    @controllerBind('ui:rerender', =>
      @update()
      'karma'
    )

  # fetch data, render view
  load: ->
    @ajax(
      id:    'karma'
      type:  'GET'
      url:   "#{@apiPath}/karma"
      success: (data) =>
        @data = data
        @render()
    )

  content: ->
    App.view('karma/index')(
      levels: @data.levels
      user: @data.user
      logs: @data.logs
    )

App.Config.set('karma', KarmaContent, 'Routes')

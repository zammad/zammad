class App.ControllerObserverActionRow extends App.ControllerObserver
  constructor: ->
    super

  render: (object) =>
    return if _.isEmpty(object)
    actions = @actions(object)
    @html App.view('generic/actions')(
      items: actions
      type:  @type
    )

    for item in actions
      do (item) =>
        @$("[data-type=\"#{item.name}\"]").on(
          'click'
          (e) ->
            e.preventDefault()
            item.callback(object)
        )

# Methods for displaying a full-screen success or error message

App.RenderScreen =
  renderScreenSuccess: (data) ->
    App.TaskManager.touch(@taskKey) if @taskKey
    (data.el || @).html App.view('generic/error/success')(data)

  renderScreenError: (data) ->
    App.TaskManager.touch(@taskKey) if @taskKey
    (data.el || @).html App.view('generic/error/generic')(data)

  renderScreenNotFound: (data) ->
    App.TaskManager.touch(@taskKey) if @taskKey
    (data.el || @).html App.view('generic/error/not_found')(data)

  renderScreenUnauthorized: (data) ->
    App.TaskManager.touch(@taskKey) if @taskKey
    (data.el || @).html App.view('generic/error/unauthorized')(data)

  renderScreenPlaceholder: (data) ->
    App.TaskManager.touch(@taskKey) if @taskKey
    (data.el || @).html App.view('generic/error/placeholder')(data)
    if data.action && data.actionCallback
      (data.el || @.el).find('.js-action').click(data.actionCallback)


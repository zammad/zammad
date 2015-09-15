class App.UiElement.input
  @render: (attribute) ->
    $( App.view('generic/input')( attribute: attribute ) )

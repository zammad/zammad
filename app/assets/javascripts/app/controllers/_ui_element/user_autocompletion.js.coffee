class App.UiElement.user_autocompletion
  @render: (attribute) ->
    new App.UserOrganizationAutocompletion( attribute: attribute ).element()

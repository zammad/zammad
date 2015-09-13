class App.UiElement.searchable_select
  @render: (attribute) ->
    new App.SearchableSelect( attribute: attribute ).element()

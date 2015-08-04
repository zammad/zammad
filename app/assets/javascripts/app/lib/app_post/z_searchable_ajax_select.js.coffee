class App.SearchableAjaxSelect extends App.SearchableSelect

  onInput: (event) =>
    super

    # send ajax request @query

  onAjaxResponse: (data) =>
    @optionsList.html App.view('generic/searchable_select_options')
      options: data

    @refreshElements()

    @filterByQuery @query
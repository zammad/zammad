class App.GitIssueLinkModal extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true

  constructor: (params) ->
    @placeholder = params.placeholder
    @head = params.head
    super

  content: ->
    $(App.view('integration/git_issue_link_modal')(
      placeholder: @placeholder
    ))

  onSubmit: (e) =>
    form = @el.find('.js-result')
    params = @formParam(form)
    return if _.isEmpty(params.link)

    @formDisable(form)
    @callback(params.link, @)


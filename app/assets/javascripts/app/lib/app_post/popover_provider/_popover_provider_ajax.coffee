class App.PopoverProviderAjax extends App.PopoverProvider
  onHide: (event, elem) ->
    $(event.target).attr('data-content', App.view('generic/page_loading')()).data('bs.popover').setContent()

  onShow: (event, elem) ->
    if @popoverLoop
      @popoverLoop = false
      return

    @fetch(event, elem)

  fetch: (event, elem) ->

  replaceOnShow: (event, content) ->
    $(event.target).popover('hide')
    $(event.target).attr('data-content', content).data('bs.popover').setContent()
    @popoverLoop = true
    $(event.target).popover('show')

  buildTitleFor: (elem) ->
    $(elem).find('[title="*"]').val()

  buildContentFor: (elem, supplementaryData) ->
    App.view('generic/page_loading')()

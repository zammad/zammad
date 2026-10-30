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
    popover = $(event.target).data('bs.popover')
    return if !popover

    # The pointer left while the content was loading: showing the tip again would keep it open, and
    #   a tip left waiting for its hide would stay loading if the pointer came back in the meantime.
    return $(event.target).popover('hide') if !popover.isInStateTrue()

    $(event.target).popover('hide')
    $(event.target).attr('data-content', content).data('bs.popover').setContent()
    @popoverLoop = true
    $(event.target).popover('show')

  buildTitleFor: (elem) ->
    $(elem).find('[title="*"]').val()

  buildContentFor: (elem, supplementaryData) ->
    App.view('generic/page_loading')()

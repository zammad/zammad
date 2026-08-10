class App.KbPopoverProvider extends App.SingleObjectPopoverProvider
  @permission = ['knowledge_base.reader', 'knowledge_base.editor']
  @templateName = 'kb_generic'
  @includeData = false
  displayTitleUsing: (object) ->
    object.title

  # The popover content lives outside of the parent controller (it is attached to the body), so the
  # tag search is bound on the built markup instead of via a controller event.
  buildHtmlContent: (params) ->
    html = super

    html.find('.js-tag').on('click', (e) ->
      e.preventDefault()
      e.stopPropagation()

      App.GlobalSearchWidget.search($(e.currentTarget).text().trim(), 'tags')
    )

    html

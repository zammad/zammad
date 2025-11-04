class ReferenceList extends App.PopoverProvider
  @selectorCssClassPrefix = 'reference-list'
  @templateName = 'reference_list'
  @titleTemplateName = 'reference_list_title'
  @includeData = false

  buildTitleFor: (elem) ->
    type  = $(elem).data('type')
    ids   = $(elem).data('ids').toString().split(',')
    title = $(elem).data('title')

    @buildHtmlTitle({ type, ids, title })

  buildContentFor: (elem) ->
    type = $(elem).data('type')
    ids  = $(elem).data('ids').toString().split(',')

    @buildHtmlContent(
      referenceList: App.view('generic/reference_list')(objects: App[type].findAll(ids))
    )

App.PopoverProvider.registerProvider('ReferenceList', ReferenceList)

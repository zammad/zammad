class ReferenceList extends App.PopoverProvider
  @selectorCssClassPrefix = 'reference-list'
  @templateName = 'reference_list'
  @titleTemplateName = 'reference_list_title'
  @includeData = false

  buildTitleFor: (elem) ->
    title = $(elem).data('title')

    @buildHtmlTitle title: title

  buildContentFor: (elem) ->
    references = $(elem).data('references')
    message    = $(elem).data('message')

    @buildHtmlContent(
      message:       message
      referenceList: _.map(references, (reference) ->
        title: reference.title
        items: App.view('generic/reference_list')(
          objects: App[reference.type].findAll(reference.ids)
        )
      )
    )

App.PopoverProvider.registerProvider('ReferenceList', ReferenceList)

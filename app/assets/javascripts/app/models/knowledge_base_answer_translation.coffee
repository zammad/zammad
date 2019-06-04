class App.KnowledgeBaseAnswerTranslation extends App.Model
  @configure 'KnowledgeBaseAnswerTranslation', 'title', 'preview', 'content', 'note', 'source', 'outdated', 'promoted', 'answer_id', 'locale_id', 'state_id'
  @extend Spine.Model.Ajax
  @extend App.KnowledgeBaseTranslationable
  @configure_attributes = [
    { name: 'title',      display: 'Name',       tag: 'input',     type: 'text', limit: 300, null: false, info: true },
    { name: 'created_at', display: 'Created at', tag: 'datetime',  readonly: 1,  info: false },
    { name: 'updated_at', display: 'Updated at', tag: 'datetime',  readonly: 1,  info: false },
  ]

  url: ->
    @parent().generateURL('translations')

  uiUrl: (action = null) ->
    @parent().uiUrl(App.KnowledgeBaseLocale.localeFor(@), action)

  publicBaseUrl: ->
    @parent().publicBaseUrl(App.KnowledgeBaseLocale.localeFor(@))

  content: ->
    App.KnowledgeBaseAnswerTranslationContent.find(@content_id)

  displayName: ->
    @title

  parent: ->
    App.KnowledgeBaseAnswer.find(@answer_id)

  remove: (options = {}) ->
    @content()?.remove(options)
    super

  attributes: ->
    attributes = super
    attributes.content = @content()?.attributes()
    attributes

  loadFull: (callback) ->
    url = @parent().generateURL() + "?full=1&include_contents=#{@content_id}"

    App.Ajax.request(
      url: url
      success: (data, status, xhr) ->
        App.Collection.loadAssets(data.assets)
        callback(true)
      error: (xhr) ->
        callback(false)

        App.Event.trigger 'notify', {
          type: 'error'
          msg: xhr.responseJSON?.error || 'Unable to load'
        }
    )

  @processAttributes: (params) ->
    if (content_params = params['content']) && _.isObject(content_params)
      delete params['content']
      params['content_attributes'] = content_params

    params

  searchResultAttributes: ->
    _.extend {}, @defaultSearchResultAttributes(),
      class: 'kb-answer-popover'
      icon:  'knowledge-base'

  @configure_overview = [
    'title', 'updated_at'
  ]

  @display_name = 'Knowledge Base Answer'

  linked_tickets: ->
    @linked_references
      .filter (elem) -> elem['link_object'] == 'Ticket'
      .map    (elem) -> App.Ticket.find(elem['link_object_value'])

class App.KnowledgeBaseAnswerTranslationContent extends App.Model
  @configure 'KnowledgeBaseAnswerTranslationContent', 'body'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/knowledge_base/translation/content'
  @configure_attributes = [
      { name: 'body', display: 'Body', tag: 'input' },
    ]

  attributes: ->
    attributes = super
    attributes.body =
      text: @body
      attachments: @attachments
    attributes

  bodyTruncated: ->
    string = @body.replace(/<([^>]+)>/g, '')

    if string.length < 100
      return string

    string.substring(0, 100) + '...'

  bodyWithPublicURLs: ->
    parsed = $("<div>#{@body}</div>")

    for linkDom in parsed.find('a').andSelf('a').toArray()
      switch $(linkDom).attr('data-target-type')
        when 'knowledge-base-answer'
          if object = App.KnowledgeBaseAnswerTranslation.find $(linkDom).attr('data-target-id')
            $(linkDom).attr 'href', object.publicBaseUrl()
          else
            $(linkDom).attr 'href', '#'

    parsed[0].innerHTML

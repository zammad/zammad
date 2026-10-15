class App.KnowledgeBaseAnswerTranslation extends App.Model
  @configure 'KnowledgeBaseAnswerTranslation', 'title', 'preview', 'content', 'note', 'source', 'outdated', 'promoted', 'answer_id', 'locale_id', 'state_id'
  @extend Spine.Model.Ajax
  @extend App.KnowledgeBaseTranslationable
  @configure_attributes = [
    { name: 'title',      display: __('Name'),       tag: 'input',     type: 'text', limit: 300, null: false, info: true },
    { name: 'created_at', display: __('Created at'), tag: 'datetime',  readonly: 1,  info: false },
    { name: 'updated_at', display: __('Updated at'), tag: 'datetime',  readonly: 1,  info: false },
  ]

  url: ->
    @parent().generateURL('translations')

  uiUrl: (action = null) ->
    @parent().uiUrl(App.KnowledgeBaseLocale.localeFor(@), action)

  publicBaseUrl: ->
    @parent().publicBaseUrl(App.KnowledgeBaseLocale.localeFor(@))

  activityMessage: (item) ->
    return if !item
    return if !item.created_by

    switch item.type
      when 'create'
        App.i18n.translateContent('Knowledge Base Answer "|%s|" has been created', item.title)
      else
        App.i18n.translateContent('Knowledge Base Answer could not be created')

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
          msg: xhr.responseJSON?.error || __('Loading failed.')
        }
    )

  contentUrl: ->
    @parent().generateURL() + "?include_contents=#{@content_id}"

  # Fetches what inserting the answer into an article puts there: its body, with the images inlined,
  # and its attachments, cloned into the article's upload cache.
  # Without a fixed request ID, so a second insertion cannot abort a clone the server already made.
  @fetchForInsertion: (url, id, formId, success, error) ->
    App.Ajax.request(
      type: 'GET'
      url:  url
      success: (data) ->
        App.Collection.loadAssets(data.assets)

        translation = App.KnowledgeBaseAnswerTranslation.find(id)
        body        = translation.content().bodyWithPublicURLs()

        App.Ajax.request(
          type: 'POST'
          data: JSON.stringify(form_id: formId)
          url:  translation.parent().generateURL('/attachments/clone_to_form')
          success: (data) ->
            App.Utils.htmlImage2DataUrlAsync(body, (output) -> success(output, data.attachments))
          error: error
        )
      error: error
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

  @display_name = __('Knowledge Base Answer')

class App.KnowledgeBaseAnswerTranslationContent extends App.Model
  @configure 'KnowledgeBaseAnswerTranslationContent', 'body'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/knowledge_base/translation/content'
  @configure_attributes = [
      { name: 'body', display: __('Body'), tag: 'input' },
    ]

  attributes: ->
    attributes = super
    attributes.body =
      text: @body
      attachments: @attachments
    attributes

  # Mirrors the answer links part of the knowledgeBaseAnswerSuggestionContentTransform mutation.
  #   Nothing resolves the links of the inserted body again, so they lose their target markers.
  bodyWithPublicURLs: ->
    parsed = $("<div>#{@constructor.linkVideoWidgets(@body)}</div>")

    for linkDom in parsed.find('a').addBack('a').toArray()
      switch $(linkDom).attr('data-target-type')
        when 'knowledge-base-answer'
          object = App.KnowledgeBaseAnswerTranslation.find $(linkDom).attr('data-target-id')
          answer = object?.parent()

          if !answer
            $(linkDom).replaceWith $(linkDom).contents()
          else
            kb_locale = App.KnowledgeBaseLocale.localeFor(object)
            href      = if answer.visiblePublicly(kb_locale) && answer.knowledge_base()?.visiblePublicly(kb_locale)
              object.publicBaseUrl()
            else
              App.Utils.joinUrlComponents(App.Utils.baseUrl(), object.uiUrl())

            $(linkDom)
              .attr('href', href)
              .removeAttr('data-target-type')
              .removeAttr('data-target-id')

    parsed[0].innerHTML

  # Mirrors KnowledgeBaseRichText.link_video_widgets: the body leaves the knowledge base for a
  #   place without an embedded player, e.g. an article sent by email.
  @linkVideoWidgets: (body) ->
    return body if !body

    parsed = $("<div>#{body}</div>")

    App.KnowledgeBaseVideo.replaceMarkersInText parsed, (settings) ->
      url = App.KnowledgeBaseVideo.watchUrl(settings)
      return if !url

      $('<a>').attr('href', url).text(url)[0]

    parsed[0].innerHTML

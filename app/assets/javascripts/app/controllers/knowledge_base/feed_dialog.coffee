class App.KnowledgeBaseFeedDialog extends App.ControllerModal
  events:
    'click .js-renew':    'clickedRenew'
    'click .js-copy': 'clickedCopy'

  head: __('Knowledge Base Feed')
  leftButtons: [
    {
      text: __('Renew Access Token'),
      className: 'js-renew'
    }
  ]
  buttonSubmit: false

  clickedCopy: (e) =>
    e.preventDefault()

    url = $(e.target).prev().attr('href')

    @copyToClipboardWithTooltip(url, e.target,'.modal-body', true)

  clickedRenew: (e) =>
    e.preventDefault()

    @token = null
    @update()

    @$('.form-control-visible-readonly').removeClass('form-control-visible-readonly')

    @ajax(
      id:          'knowledge_base_feed_token_renew'
      type:        'patch'
      url:         App.KnowledgeBase.generateURL('feed_tokens')
      processData: true
      success:     (data, status, xhr) =>
        @token = data.token
        @update()
      error:       (xhr) =>
        @showAlert(xhr.responseJSON?.error || __('Changes could not be loaded.'))
    )

  constructor: (params) ->
    super

    @load()

  load: =>
    @ajax(
      id:          'knowledge_base_feed_token'
      type:        'get'
      url:         App.KnowledgeBase.generateURL('feed_tokens')
      processData: true
      success:     (data, status, xhr) =>
        @token = data.token
        @update()
      error:       (xhr) =>
        @showAlert(xhr.responseJSON?.error || __('Changes could not be loaded.'))
    )

  content: =>
    return if !@token

    category = switch @object?.constructor
      when App.KnowledgeBaseAnswer
        @object.category()
      when App.KnowledgeBaseCategory
        @object
      else
        null

    App.view('knowledge_base/feed_dialog')(
      kb_url: @kb.privateFeedUrl(@kb_locale, @token)
      kb_title: @kb.guaranteedTitle(@kb_locale)
      category_url: category?.privateFeedUrl(@kb_locale, @token)
      category_title: category?.guaranteedTitle(@kb_locale)
    )

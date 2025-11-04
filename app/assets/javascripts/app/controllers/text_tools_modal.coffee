class App.TextToolsModal extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Approve')

  head: null
  headIcon: 'smart-assist-elaborate'
  headIconClass: 'ai-modal-head-icon ai-loading-stripe-animation'

  selectedText: null
  result: null
  approve: null

  error: false

  # Store mapping of placeholders to <img> tags
  imagePlaceholders: null

  onClose:  ->
    App.Ajax.abort('ai_assistance_text_tools')

  constructor: (params) ->
    @textTool = params.textTool
    @head = App.i18n.translatePlain('Writing Assistant: %s', App.i18n.translatePlain(@textTool.name))
    @contextData = params.contextData
    @selectedText = params.selectedText
    @approve = params.approve

    super

    @requestTextTools(
      id:              @textTool.id
      input:           @selectedText
      customer_id:     @contextData.customer_id
      group_id:        @contextData.group_id
      organization_id: @contextData.organization_id
      ticket_id:       @contextData.id
    )

  disableSubmit: ->
    button = @$('.modal-content').find('.js-submit')
    button.prop('disabled', true) if button.prop

  enableSubmit: ->
    button = @$('.modal-content').find('.js-submit')
    button.prop('disabled', false)  if button.prop

  renderFeedbackWidget: (runId) =>
    @feedbackWidget = new App.AIFeedbackWidget(
      el: @$('.text-tools-modal').find('.js-aiTextToolFeedback')
      runId: runId
      hasProvidedFeedback: false
      regenerateCallback: @retryTextTools
    )

  startStripeAnimation: ->
    $('.modal-content .ai-modal-head-icon').addClass('ai-loading-stripe-animation')

  stopStripAnimation: ->
    $('.modal-content .ai-modal-head-icon').removeClass('ai-loading-stripe-animation')

  requestTextTools: (params)  ->
    @disableSubmit()
    @startLoading()

    inputWithPlaceholders = @replaceImagesWithPlaceholders(@selectedText)
    params.input = inputWithPlaceholders.text
    @imagePlaceholders = inputWithPlaceholders.mapping

    @startStripeAnimation()
    @ajax(
      id:          'ai_assistance_text_tools'
      type:        'POST'
      url:         "#{App.Config.get('api_path')}/ai_assistance/text_tools/#{params.id}"
      data:        JSON.stringify(_.omit(params, 'id'))
      processData: true
      failResponseNoTrigger: true
      success: (data) =>
        @stopLoading()
        replaced = @restoreImagesFromPlaceholders(data.output, @imagePlaceholders)
        @result = replaced
        @update()
        @enableSubmit()
        @renderFeedbackWidget(data.analytics.run_id) if data?.analytics?.run_id
        @stopStripAnimation()

      error: =>
        @stopLoading()
        @stopStripAnimation()

        @error = true
        @update()

        @disableSubmit()
        @setupListenerForRetry()
    )

  content: -> $(App.view('generic/text_tools_modal')(
    selectedText: @selectedText
    result: @result
    error: @error
  ))

  setupListenerForRetry: =>
    @$('.modal-content').find('.js-retry').on('click',  =>
      @retryTextTools()
    )

  retryTextTools: (regenerationOfId = null) =>
    @error = false

    @requestTextTools(
      id:                 @textTool.id
      input:              @selectedText
      customer_id:        @contextData.customer_id
      group_id:           @contextData.group_id
      organization_id:    @contextData.organization_id
      ticket_id:          @contextData.id
      regeneration_of_id: regenerationOfId
    )

  onSubmit: =>
    if @feedbackWidget
      @feedbackWidget.recordUsage(context: { approved: true })

    @approve(@result)
    @close()

  replaceImagesWithPlaceholders: (text) ->
    mapping = {}
    index = 1
    # Regex to match <img ... src="data:image/..."> tags
    processed = text.replace(/<img[^>]*src=["']data:image\/[^"']*["'][^>]*>/gi, (imgTag) ->
      placeholder = "[[IMAGE_PLACEHOLDER_#{index}]]"
      mapping[placeholder] = imgTag
      index += 1
      placeholder
    )
    { text: processed, mapping: mapping }

  escapeRegExp = (string) ->
    string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')

  restoreImagesFromPlaceholders: (text, mapping) ->
    restored = text
    for placeholder, imgTag of mapping
      restored = restored.replace(new RegExp(escapeRegExp(placeholder), 'g'), imgTag)
    restored

class App.AIFeedbackWidget extends App.Controller
  runId: null
  hasProvidedFeedback: false
  regenerateCallback: null

  elements:
    '.js-aiFeedbackQuestion':       'question'
    '.js-aiFeedbackToolbar':        'toolbar'
    '.js-aiFeedbackButtons':        'buttons'
    '.js-aiFeedbackAcknowledgment': 'acknowledgment'
    '.js-aiFeedbackComment':        'comment'
    '.js-aiFeedbackAlert':          'alert'

  events:
    'click .js-aiPositiveReaction': 'submitPositiveReaction'
    'click .js-aiNegativeReaction': 'submitNegativeReaction'
    'click .js-aiRegenerate':       'regenerateResult'
    'click .js-aiCommentCancel':    'cancelComment'
    'click .js-aiCommentSubmit':    'submitComment'

  constructor: ->
    super

    @render()

  render: =>
    @html App.view('ai/ai_feedback_widget')(
      runId:               @runId
      hasRegenerate:       typeof @regenerateCallback is 'function'
      hasProvidedFeedback: @hasProvidedFeedback
    )

  recordUsage: (payload = {}, successCallback = null, errorCallback = null) =>
    return if not @runId

    @alert.addClass('hide')
    payload.ai_analytics_run_id = @runId

    @ajax(
      id:          'ai_analytics_usage_update'
      type:        'PUT'
      url:         "#{@apiPath}/ai/analytics/usages"
      data:        JSON.stringify(payload)
      processData: true
      success:     successCallback
      error:       (data, status) =>
        details = data.responseJSON || {}

        showFeedbackAlert = errorCallback?(data, status)
        return if showFeedbackAlert is false

        @alert
          .html(details.error_human || details.error || __('Your feedback could not be recorded, please try again later.'))
          .removeClass('hide')
    )

  submitPositiveReaction: (e) ->
    @preventDefault(e)

    @recordUsage(rating: true, null, =>
      @hideAcknowledgment()
      @showQuestionAndButtons()
    )

    @hideQuestionAndButtons()
    @showAcknowledgment()

  submitNegativeReaction: (e) ->
    @preventDefault(e)

    @recordUsage(rating: false, null, =>
      @hideComment()
      @showToolbar()
      @showQuestionAndButtons()
    )

    @hideQuestionAndButtons()
    @hideToolbar()
    @showComment()

  regenerateResult: (e) ->
    @preventDefault(e)

    @regenerateCallback?(@runId)

  cancelComment: (e) ->
    @preventDefault(e)

    @hideComment()
    @showToolbar()
    @showAcknowledgment()

  submitComment: (e) ->
    @preventDefault(e)

    if commentText = @comment.find('textarea').val()
      @recordUsage(comment: commentText, null, =>
        @hideAcknowledgment()
        @hideToolbar()
        @showComment()
      )

    @hideComment()
    @showToolbar()
    @showAcknowledgment()

  showQuestionAndButtons: ->
    @question.removeClass('hide')
    @buttons.removeClass('hide')

  hideQuestionAndButtons: ->
    @question.addClass('hide')
    @buttons.addClass('hide')

  showToolbar: ->
    @toolbar.removeClass('hide')

  hideToolbar: ->
    @toolbar.addClass('hide')

  showAcknowledgment: ->
    @acknowledgment.removeClass('hide')

  hideAcknowledgment: ->
    @acknowledgment.addClass('hide')

  showComment: ->
    @comment.removeClass('hide')
    return if @comment.visible()

    @comment
      .ScrollTo()
      .find('textarea')
      .focus()

  hideComment: ->
    @comment.addClass('hide')

class FeedbackAndLogs extends App.ControllerAIFeatureBase
  @requiredPermission: 'admin.ai_feedback_logs'
  header: __('Feedback & Logs')
  description: __('Download feedback from agents on AI features and error details about failed AI requests.')

  events:
    'click .js-downloadFeedback':  'downloadFeedback'
    'click .js-downloadErrorLogs': 'downloadErrorLogs'

  render: =>
    @html App.view('ai/feedback_logs')(header: @header, description: @description)

    @httpLog?.releaseController()
    @httpLog = new App.HttpLog(
      el: @$('.js-log')
      facility: 'AI::Provider'
      limit: 100
    )

    @renderAlert()

  release: ->
    @httpLog?.releaseController()
    @httpLog = null
    super

  # Feedback & Logs works independently of any configured provider connection.
  showAlert: -> false

  sendDownloadRequest: (type) ->
    isFeedback = type is 'with_usages'

    button = @$(if isFeedback then '.js-downloadFeedback' else '.js-downloadErrorLogs')

    disableButton = (disabled) -> button.prop('disabled', disabled)
    disableButton(true)

    fallbackFilename = if isFeedback then 'ai_analytics_with_usages.xlsx' else 'ai_analytics_errors.xlsx'

    App.Ajax.request(
      id: 'ai-analytics-download'
      type: 'GET'
      url: "#{@apiPath}/ai/analytics/download/#{type}"
      processData: true
      dataType: 'binary'
      contentType: 'application/octet-stream'
      xhrFields:
        responseType: 'blob'
      success: (data, status, xhr) ->
        App.Utils.downloadFileFromBlob(data, xhr, { fallbackFilename: fallbackFilename })
        disableButton(false)
      error: (xhr, status, error) =>
        @log 'error', error || status
        @notify(
          type: 'error'
          msg: __('The download could not be started. Please try again later.')
        )
        disableButton(false)
    )

  downloadFeedback: -> @sendDownloadRequest('with_usages')
  downloadErrorLogs: -> @sendDownloadRequest('errors')

App.Config.set('FeedbackAndLogs', { prio: 1060, name: __('Feedback & Logs'), parent: '#ai', target: '#ai/feedback_logs', controller: FeedbackAndLogs, permission: ['admin.ai_feedback_logs'] }, 'NavBarAdmin')

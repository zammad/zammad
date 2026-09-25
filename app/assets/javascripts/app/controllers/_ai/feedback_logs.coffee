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

  downloadFeedback: ->
    App.AIAnalyticsDownload.request(type: 'with_usages', button: @$('.js-downloadFeedback'))

  downloadErrorLogs: ->
    App.AIAnalyticsDownload.request(type: 'errors', button: @$('.js-downloadErrorLogs'))

App.Config.set('FeedbackAndLogs', { prio: 1060, name: __('Feedback & Logs'), parent: '#ai', target: '#ai/feedback_logs', controller: FeedbackAndLogs, permission: ['admin.ai_feedback_logs'] }, 'NavBarAdmin')

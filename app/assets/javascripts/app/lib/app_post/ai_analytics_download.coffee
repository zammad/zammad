# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class App.AIAnalyticsDownload
  # @param type [String] the report type, `with_usages` or `errors`
  # @param filters [Object] narrows the report down, keyed like the filters of the endpoint
  # @param button [jQuery, undefined] disabled while the request runs
  @request: ({ type, filters = {}, button }) ->
    button?.prop('disabled', true)

    App.Ajax.request(
      type:        'GET'
      url:         "#{App.Config.get('api_path')}/ai/analytics/download/#{type}"
      data:        { filters: filters }
      processData: true
      dataType:    'binary'
      contentType: 'application/octet-stream'
      xhrFields:
        responseType: 'blob'
      success: (data, status, xhr) ->
        App.Utils.downloadFileFromBlob(data, xhr, { fallbackFilename: "ai_analytics_#{type}.xlsx" })
        button?.prop('disabled', false)
      error: (xhr, status, error) ->
        App.Log.error('App.AIAnalyticsDownload', error || status)
        App.Event.trigger('notify',
          type: 'error'
          msg:  __('The download could not be started. Please try again later.')
        )
        button?.prop('disabled', false)
    )

class App.OnlineNotificationStandalone extends App.Model
  @configure 'OnlineNotificationStandalone', 'kind', 'data'

  activityMessage: (item) ->
    return if !item
    return if !item.created_by

    switch item.type
      when 'bulk_job'
        { total, failed_count } = item.objectNative?.data
        return if _.isUndefined(total) or _.isUndefined(failed_count)
        return App.i18n.translateContent('Bulk action completed for |%s| ticket(s): %s successful, %s failed', total, total - failed_count, failed_count)
      when 'kb_answer_generation_failed'
        { error_message, ticket_title } = item.objectNative?.data
        return App.i18n.translateContent('Failed to generate knowledge base draft for "%s": %s', ticket_title, error_message)
      else
        return "Unknown action for (#{@objectDisplayName()}/#{item.type}), extend activityMessage() of model."

  uiUrl: (item) ->
    undefined

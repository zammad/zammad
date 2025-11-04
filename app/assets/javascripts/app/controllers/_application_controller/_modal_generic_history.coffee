class App.GenericHistory extends App.ControllerModal
  @extend App.PopoverProvidable
  @registerPopovers 'User'

  buttonClose: true
  buttonCancel: false
  buttonSubmit: false
  head: __('History')
  shown: false

  constructor: ->
    super
    @reverse = false
    @fetch()

  content: =>
    localItem = @reworkItems(@items)

    content = $ App.view('generic/history')(
      items: localItem
    )
    content.find('a[data-type="sortorder"]').on('click', (e) =>
      e.preventDefault()
      @sortorder()
    )
    content

  onShown: =>
    @renderPopovers()

  sortorder: =>
    @reverse = !@reverse
    @update()

  T: (name) ->
    App.i18n.translateInline(name)

  sourceableTypeDisplayName: (type) ->
    {
      'PostmasterFilter': __('Postmaster Filter'),
      'Job': __('Scheduler'),
      'AI::Agent': __('AI Agent'),
    }[type] || type

  reworkItems: (items) ->
    newItems = []
    newItem = {}
    lastSource = '_'
    lastUserId = undefined
    lastTime   = undefined
    items = clone(items)
    for item in items
      if item.object is 'Ticket::Article'
        item.object = 'Article'
        if item.attribute is 'body'
          item.value_from = App.Utils.html2text(item.value_from)
          item.value_to   = App.Utils.html2text(item.value_to)
      if item.object is 'Ticket::SharedDraftZoom'
        item.object = 'Draft'
      if item.object is 'Checklist::Item'
        item.object = __('Checklist Item')

      currentItemTime = new Date( item.created_at )
      lastItemTime    = new Date( new Date( lastTime ).getTime() + (15 * 1000) )

      # start new section if user or time has changed
      if _.isEmpty(newItem) || currentItemTime > lastItemTime
        lastTime = item.created_at
        if !_.isEmpty(newItem)
          newItems.push newItem
        newItem =
          created_at: item.created_at
          created_by: App.User.find( item.created_by_id )
          sources: []

      recordsSource = _.findWhere(newItem.sources, { sourceable_id: item.sourceable_id })
      if !recordsSource
        recordsSource = {
          sourceable_id: item.sourceable_id,
          sourceable_type: @sourceableTypeDisplayName(item.sourceable_type),
          sourceable_name: item.sourceable_name,
          users: []
        }
        newItem.sources.push(recordsSource)

      recordsUser = _.findWhere(recordsSource.users, { id: item.created_by_id })
      if !recordsUser
        recordsUser = {
          id: item.created_by_id,
          object: App.User.find(item.created_by_id),
          records: [],
        }
        recordsSource.users.push(recordsUser)

      # build content
      content = ''
      if item.type is 'notification'
        content = App.i18n.translateContent( "notification sent to '%s'", item.value_to )
      if item.type is 'email'
        content = App.i18n.translateContent( "email sent to '%s'", item.value_to )
      else if item.type is 'time_trigger_performed'
        message = switch item.value_from
          when 'reminder_reached'
            __("trigger '%s' was performed because pending reminder was reached")
          when 'escalation'
            __("trigger '%s' was performed because ticket was escalated")
          when 'escalation_warning'
            __("trigger '%s' was performed because ticket will escalate soon")

        content = App.i18n.translateContent(message, item.sourceable_name)
      else if item.type is 'received_merge'
        ticket = App.Ticket.find( item.id_from )
        ticket_link = if ticket
                        "<a href=\"#ticket/zoom/#{ item.id_from }\">##{ ticket.number }</a>"
                      else
                        item.value_from
        content = App.i18n.translatePlain( 'ticket %s was merged into this ticket', ticket_link )
      else if item.type is 'merged_into'
        ticket = App.Ticket.find( item.id_to )
        ticket_link = if ticket
                        "<a href=\"#ticket/zoom/#{ item.id_to }\">##{ ticket.number }</a>"
                      else
                        item.value_to
        content = App.i18n.translatePlain( 'this ticket was merged into ticket %s', ticket_link)
      else if item.type is 'checklist_item_checked'
        content = if item.value_to is 'true'
          App.i18n.translatePlain("checked checklist item '%s'",  item.value_from)
        else
          App.i18n.translatePlain("unchecked checklist item '%s'", item.value_from)
      else if item.attribute is 'reaction'
        article_body = App.TicketArticle.find(item.o_id)?.body
        truncated_article_body = App.Utils.truncate(article_body) or '-'
        content = if item.type is 'created' or item.type is 'updated'
          if item.value_to
            App.i18n.translatePlain("reacted with a %s to message from %s '%s'", item.value_to, item.value_from, truncated_article_body)

          # NB: On MySQL backends, the reaction emoji may get stripped due to column type UTF-8 limitation (`string`).
          #   Rather than migrating this column on very heavy tables, we are opting to simply change the message here.
          #   With Zammad 7.0, MySQL support will be dropped anyway.
          else
            App.i18n.translatePlain("reacted to message from %s '%s'", item.value_from, truncated_article_body)

        else if item.type is 'removed'
          App.i18n.translatePlain("removed reaction to message from %s '%s'", item.value_from, truncated_article_body)
      else
        content = "#{ @T( item.type ) } #{ @T(item.object) } "
        if item.attribute
          content += "#{ @translateItemAttribute(item) }"

          # convert time stamps
          if item.object is 'User' && item.attribute is 'last_login'
            if item.value_from
              item.value_from = App.i18n.translateTimestamp( item.value_from )
            if item.value_to
              item.value_to = App.i18n.translateTimestamp( item.value_to )

        if item.value_from
          if item.value_to
            content += " #{ @T( 'from' ) }"
          content += " '#{ @translateItemValue(item, item.value_from) }'"

        if item.value_to
          if item.value_from || item.object is 'Mention'
            content += ' &rarr;'
          content += " '#{ @translateItemValue(item, item.value_to) }'"
        else if item.value_from && item.type isnt 'removed'
          content += " &rarr; '-'"

      recordsUser.records.push content

    if !_.isEmpty(newItem)
      newItems.push newItem

    if @reverse
      newItems = newItems.reverse()

    newItems

  translateItemValue: ({object, attribute}, value) ->
    if object is 'Mention'
      result = '-'
      if value
        user = App.User.find(value)
        if user
          result = user.displayName()
      return result

    if attribute is 'group'
      return value.replaceAll('::', ' › ')

    localAttribute = @objectAttribute(object, attribute)
    if localAttribute && localAttribute.tag is 'datetime'
      return App.i18n.translateTimestamp(value)

    if /_(time|at)$/.test(attribute)
      return App.i18n.translateTimestamp(value)

    if localAttribute && localAttribute.translate is true
      return @T(value)

    App.Utils.htmlEscape(value)

  translateItemAttribute: ({object, attribute}) ->
    localAttribute = @objectAttribute(object, attribute)
    if localAttribute && localAttribute.display
      return @T(localAttribute.display)

    @T(attribute)

  objectAttribute: (object, attribute) ->
    return if !App[object]
    return if !App[object].attributesGet()
    App[object].attributesGet()["#{attribute}_id"] ||  App[object].attributesGet()[attribute]

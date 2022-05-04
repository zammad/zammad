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
    @items = @items.reverse()
    @update()

  T: (name) ->
    App.i18n.translateInline(name)

  reworkItems: (items) ->
    newItems = []
    newItem = {}
    lastUserId = undefined
    lastTime   = undefined
    items = clone(items)
    for item in items

      if item.object is 'Ticket::Article'
        item.object = 'Article'
      if item.object is 'Ticket::SharedDraftZoom'
        item.object = 'Draft'

      data = item
      data.created_by = App.User.find( item.created_by_id )

      currentItemTime = new Date( item.created_at )
      lastItemTime    = new Date( new Date( lastTime ).getTime() + (15 * 1000) )

      # start new section if user or time has changed
      if lastUserId isnt item.created_by_id || currentItemTime > lastItemTime
        lastTime   = item.created_at
        lastUserId = item.created_by_id
        if !_.isEmpty(newItem)
          newItems.push newItem
        newItem =
          created_at: item.created_at
          created_by: App.User.find( item.created_by_id )
          records: []

      # build content
      content = ''
      if item.type is 'notification'
        content = App.i18n.translateContent( "notification sent to '%s'", item.value_to )
      if item.type is 'email'
        content = App.i18n.translateContent( "email sent to '%s'", item.value_to )
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
        else if item.value_from
          content += " &rarr; '-'"

      newItem.records.push content

    if !_.isEmpty(newItem)
      newItems.push newItem

    newItems

  translateItemValue: ({object, attribute}, value) ->
    if object is 'Mention'
      result = '-'
      if value
        user = App.User.find(value)
        if user
          result = user.displayName()
      return result

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

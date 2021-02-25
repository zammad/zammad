class App.GenericHistory extends App.ControllerModal
  @extend App.PopoverProvidable
  @registerPopovers 'User'

  buttonClose: true
  buttonCancel: false
  buttonSubmit: false
  head: 'History'
  shown: false

  constructor: ->
    super
    @fetch()

  content: =>
    localItem = @reworkItems(@items)

    content = $ App.view('generic/history')(
      items: localItem
    )
    content.find('a[data-type="sortorder"]').bind('click', (e) =>
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
      if item.type is 'notification' || item.type is 'email'
        content = "#{ @T( item.type ) } #{ @T( 'sent to' ) } '#{ item.value_to }'"
      else if item.type is 'received_merge'
        ticket = App.Ticket.find( item.id_from )
        ticket_link = if ticket
                        "<a href=\"#ticket/zoom/#{ item.id_from }\">##{ ticket.number }</a>"
                      else
                        item.value_from
        content = "#{ @T( 'Ticket' ) } #{ ticket_link } #{ @T( 'was merged into this ticket' ) }"
      else if item.type is 'merged_into'
        ticket = App.Ticket.find( item.id_to )
        ticket_link = if ticket
                        "<a href=\"#ticket/zoom/#{ item.id_to }\">##{ ticket.number }</a>"
                      else
                        item.value_to
        content = "#{ @T( 'This ticket was merged into' ) } #{ @T( 'ticket' ) } #{ ticket_link }"
      else
        content = "#{ @T( item.type ) } #{ @T(item.object) } "

        # convert time stamps
        if item.value_from
          dateObject = App.Utils.parseISO(item.value_from)
          item.value_from = App.i18n.translateTimestamp(dateObject) if dateObject
        if item.value_to
          dateObject = App.Utils.parseISO(item.value_to)
          item.value_to = App.i18n.translateTimestamp(dateObject) if dateObject

        if item.attribute
          content += "#{ @T(item.attribute) }"

        if item.value_from
          if item.value_to
            content += " #{ @T( 'from' ) }"
          content += " '#{ App.Utils.htmlEscape(item.value_from) }'"

        if item.value_to
          if item.value_from
            content += ' &rarr;'
          content += " '#{ App.Utils.htmlEscape(item.value_to) }'"
        else if item.value_from
          content += " &rarr; '-'"

      newItem.records.push content

    if !_.isEmpty(newItem)
      newItems.push newItem

    newItems

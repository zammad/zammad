class SidebarParticipants extends App.Controller
  MAX_PARTICIPANTS: 50

  sidebarItem: =>
    return if !App.Config.get('ticket_participants_enabled')
    return if @ticket.currentView() isnt 'agent'

    @item = {
      name: 'participants'
      badgeCallback: @badgeRender
      badgeIcon: 'user'
      sidebarHead: __('Participants')
      sidebarCallback: @showParticipants
      sidebarActions: @sidebarActions()
    }
    @item

  metaBadge: =>
    count = @participantCount()
    { name: 'participants', icon: 'user', counterPossible: true, counter: count }

  sidebarActions: =>
    count = @participantCount()
    return [] if count >= SidebarParticipants::MAX_PARTICIPANTS

    [{
      title:    __('+ Add')
      name:     'participant-add'
      callback: @showSearch
    }]

  participantCount: =>
    return 0 if !@mentions
    count = 0
    for m in @mentions
      user = App.User.find(m.user_id)
      continue if !user
      continue if user.permission('ticket.agent')
      continue if !user.active
      count++
    count

  showParticipants: (el) =>
    @elSidebar = el
    @reloadMentions()

  badgeRender: (el) =>
    @badgeEl = el
    @badgeRenderLocal()

  badgeRenderLocal: =>
    return if !@badgeEl
    @badgeEl.html(App.view('generic/sidebar_tabs_item')(@metaBadge()))

  render: (searchShown = false) =>
    participants = @participantMentions()
    count = participants.length
    html = App.view('ticket_zoom/sidebar_participants')(
      mentions:    participants
      canAdd:      count < SidebarParticipants::MAX_PARTICIPANTS
      canManage:   true  # Remove always available, regardless of cap
      cap:         SidebarParticipants::MAX_PARTICIPANTS
      searchShown: searchShown
    )
    @elSidebar.html(html)
    @badgeRenderLocal()
    @elSidebar.find('.js-add-participant').on('click', @add)
    @elSidebar.find('.js-remove-participant').on('click', @remove)
    @elSidebar.find('.js-search-input').on('keyup', @onSearchInput)
    if searchShown
      @elSidebar.find('.js-search-input').focus()

  participantMentions: =>
    return [] if !@mentions
    result = []
    for m in @mentions
      uid = m.user_id || m.id
      user = App.User.find(uid)
      continue if !user
      continue if !user.active
      continue if user.permission('ticket.agent')
      continue if !user.permission('ticket.customer')
      result.push({ id: m.id, user_id: uid, user: user })
    result
    result

  showSearch: =>
    @render(true)

  onSearchInput: (e) =>
    query = $(e.target).val()
    return if query.length < 2

    App.Ajax.request(
      id:    'participant_search'
      type:  'GET'
      url:   "#{@apiPath}/users/search?query=#{encodeURIComponent(query)}&limit=10&full=true"
      processData: false
      success: (data, status, xhr) =>
        if data.assets
          App.Collection.loadAssets(data.assets)
        @showSearchResults(data)
      error: =>
        @notify(type: 'error', msg: App.i18n.translateContent('Search failed.'))
    )

  showSearchResults: (data) =>
    existingIds = @participantMentions().map((m) -> m.user_id)
    available = []
    if data.assets?.User
      for own id, user of data.assets.User
        continue if parseInt(id) in existingIds
        continue if user.permissions?.includes?('ticket.agent')
        continue if !user.active
        available.push(user)
    else if _.isArray(data)
      for item in data
        continue if item.id in existingIds
        available.push(item)

    html = ''
    for user in available
      fullname = App.Utils.htmlEscape("#{user.firstname || ''} #{user.lastname || ''}".trim())
      avatarHtml = (App.User.find(user.id) || user).avatar(24)
      html += "<div class='participant-search-item js-add-participant' data-user-id='#{user.id}' style='padding:4px 6px;cursor:pointer;border-bottom:1px solid #eee;display:flex;align-items:center;'>"
      html += "<span class='avatar avatar--small' style='margin-right:6px;'>#{avatarHtml}</span>"
      html += "<span style='flex:1;'>#{fullname}</span>"
      html += "<span style='color:#999;font-size:smaller;'>#{App.Utils.htmlEscape(user.email || '')}</span>"
      html += '</div>'
    @elSidebar.find('.js-search-results').html(html || '<div class="text-muted" style="padding:4px;">No users found.</div>')
    @elSidebar.find('.js-add-participant').on('click', @add)

  add: (e) =>
    e.preventDefault()
    userId = parseInt($(e.currentTarget).attr('data-user-id'))
    return if !userId

    App.Ajax.request(
      id:    'participant_add'
      type:  'POST'
      url:   "#{@apiPath}/mentions"
      data:  "mentionable_type=Ticket&mentionable_id=#{@ticket.id}&user_id=#{userId}"
      processData: false
      contentType: 'application/x-www-form-urlencoded'
      success: (data, status, xhr) =>
        @notify(type: 'success', msg: App.i18n.translateContent('Participant added.'))
        @reloadMentions()
      error: (xhr, status, error) =>
        msg = App.i18n.translateContent('Failed to add participant.')
        try
          body = JSON.parse(xhr.responseText)
          msg = body.error || body.message || msg
        catch
        @notify(type: 'error', msg: msg)
    )

  remove: (e) =>
    e.preventDefault()
    mentionId = parseInt($(e.currentTarget).attr('data-mention-id'))
    return if !mentionId

    App.Ajax.request(
      id:    'participant_remove'
      type:  'DELETE'
      url:   "#{@apiPath}/mentions/#{mentionId}"
      processData: false
      success: (data, status, xhr) =>
        @notify(type: 'success', msg: App.i18n.translateContent('Participant removed.'))
        # Optimistic: remove from local list, re-render
        @mentions = (@mentions || []).filter((m) -> (m.id || m.user_id) != mentionId)
        @render()
      error: (xhr, status, error) =>
        msg = App.i18n.translateContent('Failed to remove participant.')
        try
          body = JSON.parse(xhr.responseText)
          msg = body.error || body.message || msg
        catch
        @notify(type: 'error', msg: msg)
    )

  reloadMentions: =>
    App.Ajax.request(
      id:    'participant_list'
      type:  'GET'
      url:   "#{@apiPath}/mentions?mentionable_type=Ticket&mentionable_id=#{@ticket.id}&full=true"
      processData: false
      success: (data, status, xhr) =>
        if data.assets
          App.Collection.loadAssets(data.assets)
        @mentions = data.record_ids?.map((id) -> App.Mention.find(id)).filter((m) -> m) || []
        @render()
    )

  reload: (args) =>
    # TicketZoom fires reload on every ticket update, often with stale mention data.
    # We manage our own state via add/remove optimistic updates. The initial
    # @mentions come from the TicketZoom constructor args and are authoritative.


App.Config.set('Participants', SidebarParticipants, 'TicketZoomSidebar')

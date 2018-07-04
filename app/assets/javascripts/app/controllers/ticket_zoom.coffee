class App.TicketZoom extends App.Controller
  elements:
    '.main':             'main'
    '.ticketZoom':       'ticketZoom'
    '.scrollPageHeader': 'scrollPageHeader'

  events:
    'click .js-submit':   'submit'
    'click .js-bookmark': 'bookmark'
    'click .js-reset':    'reset'
    'click .main':        'muteTask'

  constructor: (params) ->
    super

    # check authentication
    @authenticateCheckRedirect()

    @formMeta     = undefined
    @ticket_id    = params.ticket_id
    @article_id   = params.article_id
    @sidebarState = {}

    # if we are in init task startup, ignore overview_id
    if !params.init
      @overview_id = params.overview_id
    else
      @overview_id = undefined

    @key = "ticket::#{@ticket_id}"
    cache = App.SessionStorage.get(@key)
    if cache
      @load(cache)

    # check if ticket has beed updated every 30 min
    update = =>
      if !@initFetched
        @fetch()
        return
      @fetch(true)
    @interval(update, 1800000, 'pull_check')

    # fetch new data if triggered
    @bind('Ticket:update Ticket:touch', (data) =>

      # check if current ticket has changed
      return if data.id.toString() isnt @ticket_id.toString()

      # check if we already have the request queued
      #@log 'notice', 'TRY', @ticket_id, new Date(data.updated_at), new Date(@ticketUpdatedAtLastCall)
      @fetchMayBe(data)
    )

    # after a new websocket connection, check if ticket has changed
    @bind('spool:sent', =>
      if @initSpoolSent
        @fetch(true)
        return
      @initSpoolSent = true
    )

    # listen to rerender sidebars
    @bind('ui::ticket::sidebarRerender', (data) =>
      return if data.taskKey isnt @taskKey
      return if !@sidebarWidget
      @sidebarWidget.render(@formCurrent())
    )

  fetchMayBe: (data) =>
    if @ticketUpdatedAtLastCall
      if new Date(data.updated_at).getTime() is new Date(@ticketUpdatedAtLastCall).getTime()
        #console.log('debug no fetch, current ticket already there or requested')
        return
      if new Date(data.updated_at).getTime() < new Date(@ticketUpdatedAtLastCall).getTime()
        #console.log('debug no fetch, current ticket already newser or requested')
        return
    @ticketUpdatedAtLastCall = data.updated_at

    fetchDelayed = =>
      @fetch()
    @delay(fetchDelayed, 1000, "ticket-zoom-#{@ticket_id}")

  fetch: (ignoreSame = false) =>
    return if !@Session.get()
    queue = false
    if !@initFetched
      queue = true

    # get data
    @ajax(
      id:    "ticket_zoom_#{@ticket_id}"
      type:  'GET'
      url:   "#{@apiPath}/tickets/#{@ticket_id}?all=true"
      processData: true
      queue: queue
      success: (data, status, xhr) =>
        @load(data, ignoreSame)
        App.SessionStorage.set(@key, data)

      error: (xhr) =>
        statusText = xhr.statusText
        status     = xhr.status
        detail     = xhr.responseText

        # ignore if request is aborted
        return if statusText is 'abort'

        @renderDone = false

        # if ticket is already loaded, ignore status "0" - network issues e. g. temp. not connection
        if @ticketUpdatedAtLastCall && status is 0
          console.log('network issues e. g. temp. no connection', status, statusText, detail)
          return

        # show error message
        if status is 401 || statusText is 'Unauthorized'
          @taskHead      = '» ' + App.i18n.translateInline('Unauthorized') + ' «'
          @taskIconClass = 'diagonal-cross'
          @renderScreenUnauthorized(objectName: 'Ticket')
        else if status is 404 || statusText is 'Not Found'
          @taskHead      = '» ' + App.i18n.translateInline('Not Found') + ' «'
          @taskIconClass = 'diagonal-cross'
          @renderScreenNotFound(objectName: 'Ticket')
        else
          @taskHead      = '» ' + App.i18n.translateInline('Error') + ' «'
          @taskIconClass = 'diagonal-cross'

          if !detail
            detail = 'General communication error, maybe internet is not available!'
          @renderScreenError(
            status:     status
            detail:     detail
            objectName: 'Ticket'
          )
    )

  load: (data, ignoreSame = false, local = false) =>

    # check if ticket has changed
    newTicketRaw = data.assets.Ticket[@ticket_id]
    #console.log(newTicketRaw.updated_at)
    #console.log(@ticketUpdatedAtLastCall)

    if @ticketUpdatedAtLastCall

      # ignore if record is already shown
      if ignoreSame && new Date(newTicketRaw.updated_at).getTime() is new Date(@ticketUpdatedAtLastCall).getTime()
        #console.log('debug no fetched, current ticket already there or requested')
        return

      # do not render if newer ticket is already requested
      if new Date(newTicketRaw.updated_at).getTime() < new Date(@ticketUpdatedAtLastCall).getTime()
        #console.log('fetched no fetch, current ticket already newer')
        return

      # remember current record if newer as requested record
      if new Date(newTicketRaw.updated_at).getTime() > new Date(@ticketUpdatedAtLastCall).getTime()
        @ticketUpdatedAtLastCall = newTicketRaw.updated_at
    else
      @ticketUpdatedAtLastCall = newTicketRaw.updated_at

    # notify if ticket changed not by my self
    if @initFetched
      if newTicketRaw.updated_by_id isnt @Session.get('id')
        App.TaskManager.notify(@taskKey)
    @initFetched = true

    if !@doNotLog
      @doNotLog = 1
      @recentView('Ticket', @ticket_id)

    # remember article ids
    @ticket_article_ids = data.ticket_article_ids

    # remember link
    @links = data.links

    # remember tags
    @tags = data.tags

    # get edit form attributes
    @formMeta = data.form_meta

    # load assets
    App.Collection.loadAssets(data.assets, targetModel: 'Ticket')

    # get data
    @ticket = App.Ticket.fullLocal(@ticket_id)
    @ticket.article = undefined

    # render page
    @render(local)

  meta: =>

    # default attributes
    meta =
      url: @url()
      id:  @ticket_id

    # set icon and tilte if defined
    if @taskIconClass
      meta.iconClass = @taskIconClass
    if @taskHead
      meta.head = @taskHead

    # set icon and title based on ticket
    if @ticket_id && App.Ticket.exists(@ticket_id)
      ticket         = App.Ticket.findNative(@ticket_id)
      meta.head      = ticket.title
      meta.title     = "##{ticket.number} - #{ticket.title}"
      meta.class     = "task-state-#{ ticket.getState() }"
      meta.type      = 'task'
      meta.iconTitle = ticket.iconTitle()
      meta.iconClass = ticket.iconClass()
    meta

  url: =>
    "#ticket/zoom/#{@ticket_id}"

  show: (params) =>
    @navupdate(url: '#', type: 'menu')

    # set all notifications to seen
    App.OnlineNotification.seen('Ticket', @ticket_id)

    # if controller is executed twice, go to latest article (e. g. click on notification)
    if @activeState
      if @ticket_article_ids
        @shown = false
    @activeState = true
    @pagePosition(params)

    @positionPageHeaderStart()
    @autosaveStart()
    @shortcutNavigationStart()
    return if !@attributeBar
    @attributeBar.start()

  pagePosition: (params = {}) =>

    # remember for later
    return if params.type is 'init' && !@shown

    if params.article_id
      article_id = params.article_id
      params.article_id = undefined
    else if @pagePositionData
      article_id = @pagePositionData
      @pagePositionData = undefined

    # scroll to article if given
    scrollToPosition = (position, delay) =>
      scrollToDelay = =>
        if position is 'article'
          @scrollToArticle(article_id)
          @positionPageHeaderUpdate()
          return
        @scrollToBottom()
        @positionPageHeaderUpdate()
      @delay(scrollToDelay, delay, 'scrollToPosition')

    # trigger shown to article
    if !@shown
      @shown = true
      App.Event.trigger('ui::ticket::shown', { ticket_id: @ticket_id })
      scrollToPosition('bottom', 50)
      return

    # scroll to article if given
    if article_id && article_id isnt @last_article_id
      @last_article_id = article_id
      scrollToPosition('article', 300)
      return

    # scroll to end if new article has been added
    if !@last_ticket_article_ids || !_.isEqual(_.sortBy(@last_ticket_article_ids), _.sortBy(@ticket_article_ids))
      @last_ticket_article_ids = @ticket_article_ids
      scrollToPosition('bottom', 100)
      return

  setPosition: (position) =>
    @$('.main').scrollTop(position)

  currentPosition: =>
    element = @$('.main .ticketZoom')
    offset = element.offset()
    if offset
      position = offset.top
    Math.abs(position)

  hide: =>
    @activeState = false
    $('body > .modal').modal('hide')
    @positionPageHeaderStop()
    @autosaveStop()
    @shortcutNavigationstop()
    return if !@attributeBar
    @attributeBar.stop()

  changed: =>
    return false if !@ticket
    currentParams = @formCurrent()
    currentStore = @currentStore()
    modelDiff = @formDiff(currentParams, currentStore)
    return false if !modelDiff || _.isEmpty(modelDiff)
    return false if _.isEmpty(modelDiff.ticket) && _.isEmpty(modelDiff.article)
    return true

  release: =>
    @autosaveStop()
    @positionPageHeaderStop()

  muteTask: =>
    App.TaskManager.mute(@taskKey)

  shortcutNavigationStart: =>
    @articlePager =
      article_id: undefined

    modifier = 'alt+ctrl+left'
    $(document).bind("keydown.ticket_zoom#{@ticket_id}", modifier, (e) =>
      @articleNavigate('up')
    )
    modifier = 'alt+ctrl+right'
    $(document).bind("keydown.ticket_zoom#{@ticket_id}", modifier, (e) =>
      @articleNavigate('down')
    )

  shortcutNavigationstop: =>
    $(document).unbind("keydown.ticket_zoom#{@ticket_id}")

  articleNavigate: (direction) =>
    articleStates = []
    @$('.ticket-article .ticket-article-item').each( (_index, element) ->
      $element   = $(element)
      article_id = $element.data('id')
      visible    = $element.visible(true)
      articleStates.push {
        article_id: article_id
        visible: visible
      }
    )

    # navigate to article
    if direction is 'up'
      articleStates = articleStates.reverse()
    jumpTo = undefined
    for articleState in articleStates
      if jumpTo
        @scrollToArticle(articleState.article_id)
        @articlePager.article_id = articleState.article_id
        return
      if @articlePager.article_id
        if @articlePager.article_id is articleState.article_id
          jumpTo = articleState.article_id
      else
        if articleState.visible
          jumpTo = articleState.article_id

  positionPageHeaderStart: =>

    # init header update needed for safari, scroll event is fired
    @positionPageHeaderUpdate()

    # scroll is also fired on window resize, if element scroll is changed
    @main.bind(
      'scroll'
      @positionPageHeaderUpdate
    )

  positionPageHeaderStop: =>
    @main.unbind('scroll', @positionPageHeaderUpdate)

  @scrollHeaderPos: undefined

  positionPageHeaderUpdate: =>
    headerHeight     = @scrollPageHeader.outerHeight()
    mainScrollHeigth = @main.prop('scrollHeight')
    mainHeigth       = @main.height()

    scroll = @main.scrollTop()

    # if page header is not possible to use - mainScrollHeigth to low - hide page header
    if not mainScrollHeigth > mainHeigth + headerHeight
      @scrollPageHeader.css('transform', "translateY(#{-headerHeight}px)")

    if scroll > headerHeight
      scroll = headerHeight

    if scroll is @scrollHeaderPos
      return

    # translateY: headerHeight .. 0
    @scrollPageHeader.css('transform', "translateY(#{scroll - headerHeight}px)")

    @scrollHeaderPos = scroll

  render: (local) =>

    # update taskbar with new meta data
    App.TaskManager.touch(@taskKey)

    if !@renderDone
      @renderDone = true
      @autosaveLast = {}
      elLocal = $(App.view('ticket_zoom')
        ticket:         @ticket
        nav:            @nav
        isCustomer:     @permissionCheck('ticket.customer')
        scrollbarWidth: App.Utils.getScrollBarWidth()
        dir:            App.i18n.dir()
      )

      new App.TicketZoomOverviewNavigator(
        el:          elLocal.find('.js-overviewNavigatorContainer')
        ticket_id:   @ticket_id
        overview_id: @overview_id
      )

      new App.TicketZoomTitle(
        object_id:   @ticket_id
        overview_id: @overview_id
        el:          elLocal.find('.js-ticketTitleContainer')
        taskKey:     @taskKey
      )

      new App.TicketZoomMeta(
        object_id: @ticket_id
        el:        elLocal.find('.js-ticketMetaContainer')
      )

      @attributeBar = new App.TicketZoomAttributeBar(
        ticket:      @ticket
        el:          elLocal.find('.js-attributeBar')
        overview_id: @overview_id
        callback:    @submit
        taskKey:     @taskKey
      )
      #if @shown
      #  @attributeBar.start()

      @form_id = @taskGet('article').form_id || App.ControllerForm.formId()

      @articleNew = new App.TicketZoomArticleNew(
        ticket:    @ticket
        ticket_id: @ticket_id
        el:        elLocal.find('.article-new')
        formMeta:  @formMeta
        form_id:   @form_id
        defaults:  @taskGet('article')
        taskKey:   @taskKey
        ui:        @
      )

      @highligher = new App.TicketZoomHighlighter(
        el:        elLocal.find('.js-highlighterContainer')
        ticket_id: @ticket_id
      )

      new App.TicketZoomSetting(
        el:        elLocal.find('.js-settingContainer')
        ticket_id: @ticket_id
      )

      @articleView = new App.TicketZoomArticleView(
        ticket:             @ticket
        el:                 elLocal.find('.ticket-article')
        ui:                 @
        highligher:         @highligher
        ticket_article_ids: @ticket_article_ids
        form_id:            @form_id
      )

      new App.TicketCustomerAvatar(
        object_id: @ticket_id
        el:        elLocal.find('.ticketZoom-header')
      )

      @sidebarWidget = new App.TicketZoomSidebar(
        el:           elLocal
        sidebarState: @sidebarState
        object_id:    @ticket_id
        model:        'Ticket'
        query:        @query
        taskGet:      @taskGet
        taskKey:      @taskKey
        formMeta:     @formMeta
        markForm:     @markForm
        tags:         @tags
        links:        @links
      )

      # check if autolock is needed
      if @Config.get('ticket_auto_assignment') is true
        if @ticket.owner_id is 1 && @permissionCheck('ticket.agent') && @ticket.editable('full')
          userIdsIgnore = @Config.get('ticket_auto_assignment_user_ids_ignore') || []
          userIgnored = false
          currentUserId = App.Session.get('id')
          for userIdIgnore in userIdsIgnore
            if userIdIgnore.toString() is currentUserId.toString()
              userIgnored = true
              break
          if userIgnored is false
            ticket_auto_assignment_selector = @Config.get('ticket_auto_assignment_selector')
            if App.Ticket.selector(@ticket, ticket_auto_assignment_selector['condition'])
              assign = =>
                @ticket.owner_id = App.Session.get('id')
                @ticket.save()
              @delay(assign, 800, "ticket-auto-assign-#{@ticket.id}")

    # render init content
    if elLocal
      @html elLocal

    # show article
    else
      @articleView.execute(
        ticket_article_ids: @ticket_article_ids
      )

    if @sidebarWidget
      @sidebarWidget.reload(
        tags: @tags
        links: @links
      )

    if !@initDone
      if @article_id
        @pagePositionData = @article_id
      @pagePosition(type: 'init')
      @positionPageHeaderStart()
      @initDone = true
      return

    return if local
    @pagePosition(type: 'init')

  scrollToArticle: (article_id) =>
    articleContainer = document.getElementById("article-#{article_id}")
    return if !articleContainer
    distanceToTop = articleContainer.offsetTop - 100
    #@main.scrollTop(distanceToTop)
    @main.animate(scrollTop: distanceToTop, 100)

  scrollToBottom: =>

    # because of .ticketZoom { min-: 101% } (force to show scrollbar to set layout correctly),
    # we need to check if we need to really scroll bottom, in case of content isn't really 100%,
    # just return (otherwise just a part of movable header is shown down)
    realContentHeight = 0
    realContentHeight += @$('.ticketZoom-controls').height()
    realContentHeight += @$('.ticketZoom-header').height()
    realContentHeight += @$('.ticket-article').height()
    realContentHeight += @$('.article-new').height()
    viewableContentHeight = @$('.main').height()
    if viewableContentHeight > realContentHeight
      @main.scrollTop(0)
      return
    @main.scrollTop( @main.prop('scrollHeight') )

  autosaveStop: =>
    @clearDelay('ticket-zoom-form-update')
    @autosaveLast = {}
    @el.off('change.local blur.local keyup.local paste.local input.local')

  autosaveStart: =>
    @el.on('change.local blur.local keyup.local paste.local input.local', 'form, .js-textarea', (e) =>
      @delay(@markForm, 250, 'ticket-zoom-form-update')
    )
    @delay(@markForm, 800, 'ticket-zoom-form-update')

  markForm: (force) =>
    if !@autosaveLast
      @autosaveLast = @taskGet()
    return if !@ticket
    currentParams = @formCurrent()

    # check changed between last autosave
    sameAsLastSave = _.isEqual(currentParams, @autosaveLast)
    return if !force && sameAsLastSave
    @autosaveLast = clone(currentParams)

    # update changes in ui
    currentStore = @currentStore()
    modelDiff = @formDiff(currentParams, currentStore)

    # set followup state if needed
    @setDefaultFollowUpState(modelDiff, currentStore)

    @markFormDiff(modelDiff)
    @taskUpdateAll(modelDiff)

  currentStore: =>
    return if !@ticket
    currentStoreTicket = @ticket.attributes()
    delete currentStoreTicket.article
    internal = @Config.get('ui_ticket_zoom_article_note_new_internal')
    currentStore  =
      ticket:  currentStoreTicket
      article:
        to:          ''
        cc:          ''
        subject:     ''
        type:        'note'
        body:        ''
        internal:    internal
        in_reply_to: ''
        subtype:     ''

    if @permissionCheck('ticket.customer')
      currentStore.article.internal = ''

    currentStore

  setDefaultFollowUpState: (modelDiff, currentStore) ->

    # if the default state is set
    # and the body get changed to empty
    # then we want to reset the state
    if @isDefaultFollowUpStateSet && !modelDiff.article.body
      @$('.sidebar select[name=state_id]').val(currentStore.ticket.state_id).trigger('change')
      @isDefaultFollowUpStateSet = false
      return

    # set default if body is filled
    return if !modelDiff.article.body

    # and state got not changed
    return if modelDiff.ticket.state_id

    # and we are in the customer interface
    return if !@permissionCheck('ticket.customer')

    # and the default is was not set before
    return if @isDefaultFollowUpStateSet

    # and only if ticket is not in "new" state
    if @ticket && @ticket.state_id
      state = App.TicketState.findByAttribute('id', @ticket.state_id)
      return if state && state.default_create is true

    # prevent multiple changes for the default follow up state
    @isDefaultFollowUpStateSet = true

    # get state
    state = App.TicketState.findByAttribute('default_follow_up', true)

    # change ui and trigger change
    if state
      @$('.sidebar[data-tab=ticket] select[name=state_id]').val(state.id).trigger('change')

    true

  resetDefaultFollowUpState: ->
    @isDefaultFollowUpStateSet = false

  formCurrent: =>
    currentParams =
      ticket:  @formParam(@el.find('.edit'))
      article: @articleNew.params()

    # add attachments if exist
    attachmentCount = @$('.article-add .textBubble .attachments .attachment').length
    if attachmentCount > 0
      currentParams.article.attachments = true
    else
      delete currentParams.article.attachments

    delete currentParams.article.form_id

    if @permissionCheck('ticket.customer')
      currentParams.article.internal = ''

    currentParams

  formDiff: (currentParams, currentStore) ->

    # do not compare null or undefined value
    if currentStore.ticket
      for key, value of currentStore.ticket
        if value is null || value is undefined
          currentStore.ticket[key] = ''
    if currentParams.ticket
      for key, value of currentParams.ticket
        if value is null || value is undefined
          currentParams.ticket[key] = ''

    # get diff of model
    modelDiff =
      ticket:  @forRemoveMeta(App.Utils.formDiff(currentParams.ticket, currentStore.ticket))
      article: @forRemoveMeta(App.Utils.formDiff(currentParams.article, currentStore.article))
    modelDiff

  forRemoveMeta: (params = {}) ->
    paramsNew = {}
    for key, value of params
      if !key.match(/_completion$/)
        paramsNew[key] = value
    paramsNew

  markFormDiff: (diff = {}) =>
    ticketForm    = @$('.edit')
    ticketSidebar = @$('.tabsSidebar-tab[data-tab="ticket"]')
    articleForm   = @$('.article-add')
    resetButton   = @$('.js-reset')

    params         = {}
    params.ticket  = @forRemoveMeta(@formParam(ticketForm))
    params.article = @forRemoveMeta(@formParam(articleForm))

    # clear all changes
    if _.isEmpty(diff.ticket) && _.isEmpty(diff.article)
      ticketSidebar.removeClass('is-changed')
      ticketForm.removeClass('form-changed')
      ticketForm.find('.form-group').removeClass('is-changed')
      resetButton.addClass('hide')

    # set changes
    else
      ticketForm.addClass('form-changed')
      if !_.isEmpty(diff.ticket)
        ticketSidebar.addClass('is-changed')
      else
        ticketSidebar.removeClass('is-changed')
      for currentKey, currentValue of params.ticket
        element = @$('.edit [name="' + currentKey + '"]').parents('.form-group')
        if !element.get(0)
          element = @$('.edit [data-name="' + currentKey + '"]').parents('.form-group')
        if currentKey of diff.ticket
          if !element.hasClass('is-changed')
            element.addClass('is-changed')
        else
          if element.hasClass('is-changed')
            element.removeClass('is-changed')

      resetButton.removeClass('hide')

  submit: (e, macro = {}) =>
    e.stopPropagation()
    e.preventDefault()

    # disable form
    @formDisable(e)

    # validate new article
    if !@articleNew.validate()
      @formEnable(e)
      return

    ticketParams = @formParam(@$('.edit'))

    # validate ticket
    # we need to use the full ticket because
    # the time accouting needs all attributes
    # for condition check
    ticket = App.Ticket.fullLocal(@ticket_id)

    # reset article - should not be resubmited on next ticket update
    ticket.article = undefined

    # update ticket attributes
    for key, value of ticketParams
      ticket[key] = value

    App.Ticket.macro(
      macro: macro
      ticket: ticket
      callback:
        tagAdd: (tag) =>
          return if !@sidebarWidget
          return if !@sidebarWidget.reload
          @sidebarWidget.reload(tagAdd: tag, source: 'macro')
        tagRemove: (tag) =>
          return if !@sidebarWidget
          return if !@sidebarWidget.reload
          @sidebarWidget.reload(tagRemove: tag)
    )

    # set defaults
    if !@permissionCheck('ticket.customer')
      if !ticket['owner_id']
        ticket['owner_id'] = 1

    # if title is empty - ticket can't processed, set ?
    if _.isEmpty(ticket.title)
      ticket.title = '-'

    # stop autosave
    @autosaveStop()

    # validate ticket
    errors = ticket.validate(
      screen: 'edit'
    )
    if errors
      @log 'error', 'update', errors
      @formValidate(
        form:   @$('.edit')
        errors: errors
        screen: 'edit'
      )
      @formEnable(e)
      @autosaveStart()
      return

    articleParams = @articleNew.params()
    if articleParams && articleParams.body
      article = new App.TicketArticle
      article.load(articleParams)
      errors = article.validate()
      if errors
        @log 'error', 'update article', errors
        @formValidate(
          form:   @$('.article-add')
          errors: errors
          screen: 'edit'
        )
        @formEnable(e)
        @autosaveStart()
        return

      ticket.article = article

    if !ticket.article
      @submitPost(e, ticket)
      return

    # verify if time accounting is enabled
    if @Config.get('time_accounting') isnt true
      @submitPost(e, ticket)
      return

    # verify if time accounting is active for ticket
    time_accounting_selector = @Config.get('time_accounting_selector')
    if !App.Ticket.selector(ticket, time_accounting_selector['condition'])
      @submitPost(e, ticket)
      return

    # time tracking
    if @permissionCheck('ticket.customer')
      @submitPost(e, ticket)
      return

    new App.TicketZoomTimeAccounting(
      container: @el.closest('.content')
      ticket: ticket
      cancelCallback: =>
        @formEnable(e)
      submitCallback: (params) =>
        if params.time_unit
          ticket.article.time_unit = params.time_unit
        @submitPost(e, ticket)
    )

  submitPost: (e, ticket) =>

    taskAction = @$('.js-secondaryActionButtonLabel').data('type')

    # submit changes
    @ajax(
      id: "ticket_update_#{ticket.id}"
      type: 'PUT'
      url: "#{App.Ticket.url}/#{ticket.id}?all=true"
      data: JSON.stringify(ticket.attributes())
      processData: true
      success: (data) =>

        #App.SessionStorage.set(@key, data)
        @load(data, true, true)

        # reset article - should not be resubmited on next ticket update
        ticket.article = undefined

        # reset form after save
        @reset()

        if @sidebarWidget
          @sidebarWidget.commit()

        if taskAction is 'closeNextInOverview'
          if @overview_id
            current_position = 0
            overview = App.Overview.find(@overview_id)
            list = App.OverviewListCollection.get(overview.link)
            for ticket in list.tickets
              current_position += 1
              if ticket.id is @ticket_id
                next = list.tickets[current_position]
                if next
                  # close task
                  App.TaskManager.remove(@taskKey)

                  # open task via task manager to get overview information
                  App.TaskManager.execute(
                    key:        'Ticket-' + next.id
                    controller: 'TicketZoom'
                    params:
                      ticket_id:   next.id
                      overview_id: @overview_id
                    show:       true
                  )
                  @navigate "ticket/zoom/#{next.id}"
                  return

          # fallback, close task
          taskAction = 'closeTab'

        if taskAction is 'closeTab'
          App.TaskManager.remove(@taskKey)
          nextTaskUrl = App.TaskManager.nextTaskUrl()
          if nextTaskUrl
            @navigate nextTaskUrl
            return

          @navigate '#'
          return

        @autosaveStart()
        @muteTask()
        @formEnable(e)
        App.Event.trigger('overview:fetch')

      error: (settings, details) =>
        App.Event.trigger 'notify', {
          type:    'error'
          msg:     App.i18n.translateContent(details.error_human || details.error || settings.responseJSON.error || 'Unable to update!')
          timeout: 2000
        }
        @autosaveStart()
        @muteTask()
        @fetch()
        @formEnable(e)
    )

  bookmark: (e) ->
    $(e.currentTarget).find('.bookmark.icon').toggleClass('filled')

  reset: (e) =>
    if e
      e.preventDefault()

    # reset task
    @taskReset()

    # reset default follow up state
    @resetDefaultFollowUpState()

    # reset/delete uploaded attachments
    App.Ajax.request(
      type:  'DELETE'
      url:   App.Config.get('api_path') + '/ticket_attachment_upload'
      data:  JSON.stringify(form_id: @form_id)
      processData: false
    )

    # hide reset button
    @$('.js-reset').addClass('hide')

    # reset edit ticket / reset new article
    App.Event.trigger('ui::ticket::taskReset', { ticket_id: @ticket_id })

    # remove change flag on tab
    @$('.tabsSidebar-tab[data-tab="ticket"]').removeClass('is-changed')

  taskGet: (area) =>
    return {} if !App.TaskManager.get(@taskKey)
    @localTaskData = App.TaskManager.get(@taskKey).state || {}

    if _.isObject(@localTaskData.article) && _.isArray(App.TaskManager.get(@taskKey).attachments)
      @localTaskData.article['attachments'] = App.TaskManager.get(@taskKey).attachments

    if area
      if !@localTaskData[area]
        @localTaskData[area] = {}
      return @localTaskData[area]
    if !@localTaskData
      @localTaskData = {}
    @localTaskData

  taskUpdate: (area, data) =>
    @localTaskData[area] = data
    App.TaskManager.update(@taskKey, { 'state': @localTaskData })

  taskUpdateAll: (data) =>
    @localTaskData = data
    @localTaskData.article['form_id'] = @form_id
    App.TaskManager.update(@taskKey, { 'state': @localTaskData })

  # reset task state
  taskReset: =>
    @form_id = App.ControllerForm.formId()
    @articleNew.form_id = @form_id
    @articleNew.render()

    @localTaskData =
      ticket:  {}
      article: {}
    App.TaskManager.update(@taskKey, { 'state': @localTaskData })

class TicketZoomRouter extends App.ControllerPermanent
  requiredPermission: ['ticket.agent', 'ticket.customer']
  constructor: (params) ->
    super

    # cleanup params
    clean_params =
      ticket_id:  params.ticket_id
      article_id: params.article_id
      nav:        params.nav
      shown:      true

    App.TaskManager.execute(
      key:        "Ticket-#{@ticket_id}"
      controller: 'TicketZoom'
      params:     clean_params
      show:       true
    )

App.Config.set('ticket/zoom/:ticket_id', TicketZoomRouter, 'Routes')
App.Config.set('ticket/zoom/:ticket_id/nav/:nav', TicketZoomRouter, 'Routes')
App.Config.set('ticket/zoom/:ticket_id/:article_id', TicketZoomRouter, 'Routes')

class App.TicketZoom extends App.Controller
  @include App.TicketNavigable

  elements:
    '.main':             'main'
    '.ticketZoom':       'ticketZoom'
    '.scrollPageHeader': 'scrollPageHeader'
    '.scrollPageAlert':  'scrollPageAlert'

  events:
    'click .js-submit':                                          'submit'
    'click .js-bookmark':                                        'bookmark'
    'click .js-reset':                                           'reset'
    'click .js-draft':                                           'draft'
    'click .main':                                               'muteTask'
    'click .ticket-number-copy-header > .ticketNumberCopy-icon': 'copyTicketNumber'

  constructor: (params) ->
    super

    @formMeta      = undefined
    @ticket_id     = parseInt(params.ticket_id)
    @article_id    = params.article_id
    @sidebarState  = {}
    @tooltipCopied = undefined
    @init          = params.init

    # if we are in init task startup, ignore overview_id
    if !params.init
      @overview_id = params.overview_id
    else
      @overview_id = undefined

    @key = "ticket::#{@ticket_id}"
    cache = App.SessionStorage.get(@key)
    if cache
      @load(cache)

    # check if ticket has been updated every 30 min
    update = =>
      @fetch()

    @interval(update, 1800000, 'pull_check')

    # fetch new data if triggered
    @controllerBind('Ticket:update Ticket:touch', (data) =>

      # check if current ticket has changed
      return if data.id.toString() isnt @ticket_id.toString()

      # check if we already have the request queued
      #@log 'notice', 'TRY', @ticket_id, new Date(data.updated_at), new Date(@ticketUpdatedAtLastCall)
      @fetchMayBe(data)
    )

    # after a new websocket connection, check if ticket has changed
    @controllerBind('ws:login', =>
      if @initiallyFetched
        @fetch()
        return
      @initiallyFetched = true
    )

    # listen to rerender sidebars
    @controllerBind('ui::ticket::sidebarRerender', (data) =>
      return if data.taskKey isnt @taskKey
      return if !@sidebarWidget
      @sidebarWidget.render(@formCurrent())
    )
    @controllerBind('config_update', (data) =>
      return if data.name isnt 'checklist'
      @renderDone = false
      @render()
    )

  fetchMayBe: (data) =>
    return if @ticketUpdatedAtLastCall && new Date(data.updated_at).getTime() <= new Date(@ticketUpdatedAtLastCall).getTime()

    fetchDelayed = =>
      @fetch()
    @delay(fetchDelayed, 1000, "ticket-zoom-#{@ticket_id}")

  fetch: =>
    return if !@Session.get()
    queue = false
    if !@initFetched
      queue = true

    if @init
      @init = false
      initTicket = App.TaskbarInit.ticket(@ticket_id)
      return @load(initTicket, false, App.Ticket.fullLocal(@ticket_id)) if initTicket

    # get data
    @ajax(
      id:    "ticket_zoom_#{@ticket_id}"
      type:  'GET'
      url:   "#{@apiPath}/tickets/#{@ticket_id}?all=true&auto_assign=true"
      processData: true
      queue: queue
      success: (data, status, xhr) =>
        @load(data)
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
        if status is 403 || statusText is 'Not authorized'
          @taskHead      = '» ' + App.i18n.translateInline('Not authorized') + ' «'
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
            detail = __('General communication error, maybe internet is not available!')
          @renderScreenError(
            status:     status
            detail:     detail
            objectName: 'Ticket'
          )
    )

  load: (data, local = false, newTicketRaw = undefined) =>
    if !newTicketRaw
      newTicketRaw = data.assets.Ticket[@ticket_id]

    view       = @ticket?.currentView()
    readable   = @ticket?.userGroupAccess('read')
    changeable = @ticket?.userGroupAccess('change')
    fullable   = @ticket?.userGroupAccess('full')
    formMeta   = data.form_meta

    # on the following states we want to rerender the ticket:
    # - if the object attribute configuration has changed (attribute values, dependencies, filters)
    # - if the user view has changed (agent/customer)
    # - if the ticket permission has changed (read/write/full)
    if @view && ( !_.isEqual(@formMeta.configure_attributes, formMeta.configure_attributes) || !_.isEqual(@formMeta.dependencies, formMeta.dependencies) || !_.isEqual(@formMeta.filter, formMeta.filter) || @view isnt view || @readable isnt readable || @changeable isnt changeable || @fullable isnt fullable )
      @renderDone = false

    ticketIsNewest = @ticketUpdatedAtLastCall && new Date(newTicketRaw.updated_at).getTime() <= new Date(@ticketUpdatedAtLastCall).getTime()
    return if @renderDone && ticketIsNewest
    @ticketUpdatedAtLastCall = newTicketRaw.updated_at

    # notify if ticket changed not by my self
    if @initFetched && !ticketIsNewest && newTicketRaw.updated_by_id isnt @Session.get('id')
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

    # remember mentions
    @mentions = data.mentions

    # remember time_accountings
    @time_accountings = data.time_accountings

    if draft = App.TicketSharedDraftZoom.findByAttribute 'ticket_id', @ticket_id
      draft.remove(clear: true)

    App.Collection.loadAssets(data.assets, targetModel: 'Ticket')

    # get ticket
    @ticket         = App.Ticket.fullLocal(@ticket_id)
    @ticket.article = undefined
    @view           = @ticket.currentView()
    @readable       = @ticket.userGroupAccess('read')
    @changeable     = @ticket.userGroupAccess('change')
    @fullable       = @ticket.userGroupAccess('full')
    @formMeta       = data.form_meta

    # render page
    # Due to modification of @renderDone in @render, we need to save the value
    beforeRenderDone = @renderDone
    @render(local)

    if beforeRenderDone
      App.Event.trigger('ui::ticket::load', data)

    App.Event.trigger('ui::ticket::all::loaded', data)

  meta: =>

    # default attributes
    meta =
      url: @url()
      id:  @ticket_id

    # set icon and title if defined
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

    # initially hide on mobile
    if window.matchMedia('(max-width: 767px)').matches
      @el.find('.tabsSidebar').addClass('is-closed')
      @el.find('.tabsSidebar-sidebarSpacer').addClass('is-closed')

    # if controller is executed twice, go to latest article (e. g. click on notification)
    if @activeState
      if @ticket_article_ids
        @shown = false
    @activeState = true
    @pagePosition(params)

    @positionPageHeaderStart()
    @autosaveStart()
    @shortcutNavigationStart()

    if @articleNew
      @articleNew.show()

    return if !@attributeBar
    @attributeBar.start()

    if @renderDone && params.overview_id? && @overview_id != params.overview_id
      @overview_id = params.overview_id

      @renderOverviewNavigator(@el)

  # scroll to article if given
  scrollToPosition: (position, delay, article_id) =>
    scrollToDelay = =>
      if position is 'article'
        @scrollToArticle(article_id)
        @positionPageHeaderUpdate()
        return
      @scrollToBottom()
      @positionPageHeaderUpdate()
    @delay(scrollToDelay, delay, 'scrollToPosition')

  pagePosition: (params = {}) =>
    return if @el.is(':hidden')

    # remember for later
    return if params.type is 'init' && !@shown

    if params.article_id
      article_id = params.article_id
      params.article_id = undefined
    else if @pagePositionData
      article_id = @pagePositionData
      @pagePositionData = undefined

    # scroll to article if given
    if article_id && article_id isnt @last_article_id
      @scrollToPosition('article', 300, article_id)

    # scroll to end if new article has been added
    else if !@last_ticket_article_ids || !_.isEqual(_.sortBy(@last_ticket_article_ids), _.sortBy(@ticket_article_ids))
      App.Event.trigger('ui::ticket::shown', { ticket_id: @ticket_id })
      @scrollToPosition('bottom', 100, article_id)

    # trigger shown to article
    else if !@shown
      App.Event.trigger('ui::ticket::shown', { ticket_id: @ticket_id })
      @scrollToPosition('bottom', 50, article_id)

    # save page position state
    @shown                   = true
    @last_ticket_article_ids = @ticket_article_ids
    @last_article_id         = article_id

  setPosition: (position) =>
    @$('.main').scrollTop(position)

  currentPosition: =>
    element = @$('.main .ticketZoom')
    offset = element.offset()
    if offset
      position = offset.top

      # Subtract possible top padding of the parent container.
      position -= parseInt(element.parent().css('paddingTop') or 0, 10)

    Math.abs(position)

  hide: =>
    @activeState = false
    $('body > .modal').modal('hide') if @shown
    @positionPageHeaderStop()
    @autosaveStop()
    @shortcutNavigationstop()
    @hideCopyTicketNumberTooltip()
    return if !@attributeBar
    @attributeBar.stop()

  changed: (object, field) =>
    return false if !@ticket
    currentParams = @formCurrent()
    currentStore = @currentStore()
    modelDiff = @formDiff(currentParams, currentStore)
    return false if !modelDiff || _.isEmpty(modelDiff)
    return false if _.isEmpty(modelDiff.ticket) && _.isEmpty(modelDiff.article)
    return not _.isUndefined(modelDiff[object]?[field]) if object and field
    return true

  release: =>
    @autosaveStop()
    @positionPageHeaderStop()
    @sidebarWidget?.releaseController()

  muteTask: =>
    App.TaskManager.mute(@taskKey)

  shortcutNavigationStart: =>
    @articlePager =
      article_id: undefined

    modifier = 'left'
    $(document).on("keydown.ticket_zoom#{@ticket_id}", {keys: modifier}, (e) =>
      return if App.KeyboardShortcutPlugin.isInput()
      @articleNavigate('ascending')
    )
    modifier = 'right'
    $(document).on("keydown.ticket_zoom#{@ticket_id}", {keys: modifier}, (e) =>
      return if App.KeyboardShortcutPlugin.isInput()
      @articleNavigate('descending')
    )

  shortcutNavigationstop: =>
    $(document).off("keydown.ticket_zoom#{@ticket_id}")

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
    if direction is 'ascending'
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
    @main.on(
      'scroll'
      @positionPageHeaderUpdate
    )

  positionPageHeaderStop: =>
    @main.off('scroll', @positionPageHeaderUpdate)

  @scrollHeaderPos: undefined

  positionPageHeaderUpdate: =>
    headerHeight     = @scrollPageHeader.outerHeight()
    alertHeight      = if @isPageAlertVisible() then @scrollPageAlert.outerHeight() else 0
    mainScrollHeight = @main.prop('scrollHeight')
    mainHeight       = @main.height()

    scroll = @main.scrollTop()

    # if page header is not possible to use - mainScrollHeight to low - hide page header
    if not mainScrollHeight > mainHeight + headerHeight
      @scrollPageHeader.css('transform', "translateY(#{-headerHeight}px)")

      if alertHeight
        @scrollPageAlert.css('transform', 'translateY(0)')
        @main.css('paddingTop', "#{alertHeight}px")
      else
        @main.css('paddingTop', '0')

      return

    if scroll > headerHeight
      scroll = headerHeight

    if scroll is @scrollHeaderPos
      @hideCopyTicketNumberTooltip()
      return

    # translateY: headerHeight .. 0
    @scrollPageHeader.css('transform', "translateY(#{scroll - headerHeight}px)")

    if alertHeight
      @scrollPageAlert.css('transform', "translateY(#{scroll}px)")
      @main.css('paddingTop', "#{scroll + alertHeight}px")
    else
      @main.css('paddingTop', '0')

    @scrollHeaderPos = scroll

  isPageAlertVisible: =>
    not @scrollPageAlert.hasClass('hide')

  pendingTimeReminderReached: =>
    App.TaskManager.touch(@taskKey)

  setPendingTimeReminderDelay: =>
    stateType = App.TicketStateType.find @ticket?.state?.state_type_id
    return if stateType?.name != 'pending reminder'

    delay = new Date(@ticket.pending_time) - new Date()

    @delay @pendingTimeReminderReached, delay, 'pendingTimeReminderDelay'

  articleParams: =>
    return @articleNew?.params()

  render: (local) =>
    @setPendingTimeReminderDelay()

    # update taskbar with new meta data
    App.TaskManager.touch(@taskKey)

    if !@renderDone
      @renderDone      = true
      @autosaveLast    = {}
      @scrollHeaderPos = undefined

      elLocal = $(App.view('ticket_zoom')
        ticket:         @ticket
        nav:            @nav
        scrollbarWidth: App.Utils.getScrollBarWidth()
        dir:            App.i18n.dir()
      )

      @renderOverviewNavigator(elLocal)

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
        ticket:        @ticket
        el:            elLocal.find('.js-attributeBar')
        overview_id:   @overview_id
        macroCallback: @submit
        draftCallback: @saveDraft
        draftState:    @draftState()
        taskKey:       @taskKey
      )
      #if @shown
      #  @attributeBar.start()

      @form_id = @taskGet('article').form_id || App.ControllerForm.formId()

      if @ticket.editable()
        @articleNew = new App.TicketZoomArticleNew(
          ticket:                       @ticket
          ticket_id:                    @ticket_id
          el:                           elLocal.find('.article-new')
          formMeta:                     @formMeta
          form_id:                      @form_id
          defaults:                     @taskGet('article')
          taskKey:                      @taskKey
          ui:                           @
          richTextUploadStartCallback:  @submitDisable
          richTextUploadRenderCallback: (attachments) =>
            @submitEnable()
            @taskUpdateAttachments('article', attachments)
            @delay(@markForm, 250, 'ticket-zoom-form-update')
          richTextUploadDeleteCallback: (attachments) =>
            @taskUpdateAttachments('article', attachments)
            @delay(@markForm, 250, 'ticket-zoom-form-update')
        )

        @highlighter = new App.TicketZoomHighlighter(
          el:        elLocal.find('.js-highlighterContainer')
          ticket:    @ticket
          ticket_id: @ticket_id
        )

        # Check if the alert should be shown.
        #   Normally, this is a concern of the associated channel, so we only render it if it's known.
        if @ticket.preferences?.channel_id
          new App.TicketZoomAlert(
            el:        elLocal.find('.js-ticketAlertContainer')
            object_id: @ticket_id
          )

      new App.TicketZoomSetting(
        el:        elLocal.find('.js-settingContainer')
        ticket_id: @ticket_id
      )

      @articleView = new App.TicketZoomArticleView(
        ticket:             @ticket
        el:                 elLocal.find('.ticket-article')
        ui:                 @
        highlighter:        @highlighter
        ticket_article_ids: @ticket_article_ids
        form_id:            @form_id
      )

      new App.TicketCustomerAvatar(
        object_id: @ticket_id
        el:        elLocal.find('.ticketZoom-header')
      )

      new App.TicketOrganizationAvatar(
        object_id: @ticket_id
        el:        elLocal.find('.ticketZoom-header')
      )

      @sidebarWidget = new App.TicketZoomSidebar(
        el:               elLocal
        sidebarState:     @sidebarState
        object_id:        @ticket_id
        model:            'Ticket'
        query:            @query
        taskGet:          @taskGet
        taskKey:          @taskKey
        formMeta:         @formMeta
        markForm:         @markForm
        tags:             @tags
        mentions:         @mentions
        time_accountings: @time_accountings
        links:            @links
        parent:           @
      )

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
        tags:             @tags
        mentions:         @mentions
        time_accountings: @time_accountings
        links:            @links
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
    return if !@ticket.editable()
    currentParams = @formCurrent()

    # check changed between last autosave
    sameAsLastSave = _.isEqual(currentParams, @autosaveLast)
    return if !force && sameAsLastSave
    @autosaveLast = clone(currentParams)

    # update changes in ui
    currentStore = @currentStore()
    modelDiff = @formDiff(currentParams, currentStore)
    return if _.isEmpty(modelDiff)

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
        internal:    ''
        in_reply_to: ''
        subtype:     ''

    if @ticket.currentView() is 'agent'
      currentStore.article.internal = internal

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
    return if @ticket.currentView() isnt 'customer'

    # and the default is was not set before
    return if @isDefaultFollowUpStateSet

    # and only if ticket is not in "new" state
    if @ticket && @ticket.state_id
      state = App.TicketState.findByAttribute('id', @ticket.state_id)
      return if state && state.default_create is true

    # prevent multiple changes for the default follow-up state
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
      article: @articleNew?.params() || {}

    # add attachments if exist
    attachmentCount = @$('.article-add .textBubble .attachments .attachment').length
    if attachmentCount > 0
      currentParams.article.attachments = attachmentCount
    else
      delete currentParams.article.attachments

    delete currentParams.article.form_id

    if @ticket.currentView() is 'customer'
      currentParams.article.internal = ''

    currentParams

  formDiff: (currentParams, currentStore) ->

    # do not compare null or undefined value
    if currentStore.ticket

      # make sure that the compared state is same in local storage and
      # rendered html. Else we could have race conditions of data
      # which is not rendered yet
      renderedUpdatedAt = @el.find('.edit').attr('data-ticket-updated-at')
      return if !renderedUpdatedAt
      return if currentStore.ticket.updated_at.toString() isnt renderedUpdatedAt

      @formDiffSimplifyEmptyValues(currentStore)
    if currentParams.ticket
      @formDiffSimplifyEmptyValues(currentParams)

    articleDiff = @forRemoveMeta(App.Utils.formDiff(currentParams.article, currentStore.article))

    if articleDiff.type
      articleDiff.internal = currentParams.article.internal

    articleDiffKeys = _.keys(articleDiff)
    contentKeys     = _.difference(articleDiffKeys, ['type', 'internal'])

    if _.isEmpty(contentKeys)
      delete articleDiff.type
      delete articleDiff.internal

    {
      ticket:  @forRemoveMeta(App.Utils.formDiff(currentParams.ticket, currentStore.ticket))
      article: articleDiff
    }

  formDiffSimplifyEmptyValues: (params) ->
    for key, value of params.ticket
      if value is null || value is undefined
        params.ticket[key] = ''

      tagName = App.Ticket.configure_attributes.find((elem) -> elem.name == key)?.tag

      if ['multiselect', 'multi_tree_select'].includes(tagName)
        if _.isEmpty(value) || _.isEqual(value, [''])
          params.ticket[key] = ''

  forRemoveMeta: (params = {}) ->
    paramsNew = {}
    for key, value of params
      if !key.match(/_completion$/)
        paramsNew[key] = value
    paramsNew

  markFormDiff: (diff = {}) =>
    ticketForm    = @$('.edit')
    ticketSidebar = @$('.tabsSidebar-tab[data-tab="ticket"]')
    resetButton   = @$('.js-reset')

    params         = {}
    params.ticket  = @forRemoveMeta(@ticketParams())
    params.article = @forRemoveMeta(@articleNew?.params())

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

  ticketParams: =>
    @formParam(@$('.edit'))

  submitDisable: (e) =>
    if e
      @formDisable(e)
      return
    @formDisable(@$('.js-submitDropdown'))

  submitEnable: (e) =>
    if e
      @formEnable(e)
      return
    @formEnable(@$('.js-submitDropdown'))

  submit: (e, macro = {}) =>
    e.stopPropagation()
    e.preventDefault()

    # disable form
    @submitDisable(e)

    # validate new article
    if !@articleNew.validate()
      @submitEnable(e)
      return

    ticketParams = @ticketParams()
    articleParams = @articleParams()

    # validate ticket
    # we need to use the full ticket because
    # the time accouting needs all attributes
    # for condition check
    ticket = App.Ticket.fullLocal(@ticket_id)

    # reset article - should not be resubmitted on next ticket update
    ticket.article = undefined

    # update ticket attributes
    for key, value of ticketParams
      ticket[key] = value

    if macro.perform
      App.Ticket.macro(
        macro: macro.perform
        ticket: ticket
        article: articleParams
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
    if ticket.currentView() is 'agent'
      if !ticket['owner_id']
        ticket['owner_id'] = 1

    # if title is empty - ticket can't processed, set ?
    if _.isEmpty(ticket.title)
      ticket.title = '-'

    # stop autosave
    @autosaveStop()

    # no form validation if macro is performed
    if !macro.perform

      # validate ticket form using HTML5 validity check
      element = @$('.edit').parent().get(0)
      if element && element.reportValidity && !element.reportValidity()
        @submitEnable(e)
        @autosaveStart()
        return

    editContollerForm = @sidebarWidget?.get('100-TicketEdit')?.edit?.controllerFormSidebarTicket

    # validate ticket by model
    errors = ticket.validate(
      controllerForm: editContollerForm
      target: e.target
    )
    if errors
      @log 'error', 'update', errors
      @formValidate(
        form:   @$('.edit')
        errors: errors
        screen: 'edit'
      )
      @submitEnable(e)
      @autosaveStart()
      return

    # New article body required.
    # But WhatsApp messages with some attachments go without adjacent text.
    if articleParams && (articleParams.body || @articleNew?.checkBodyAllowEmpty())
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
        @submitEnable(e)
        @autosaveStart()
        return

      ticket.article = article

    # add sidebar params
    if @sidebarWidget && @sidebarWidget.postParams
      @sidebarWidget.postParams(ticket: ticket)

    @submitChecklist(e, ticket, macro, editContollerForm)

  submitChecklist: (e, ticket, macro, editContollerForm) =>
    return @submitTimeAccounting(e, ticket, macro, editContollerForm) if ticket.currentView() isnt 'agent'
    return @submitTimeAccounting(e, ticket, macro, editContollerForm) if !App.Config.get('checklist')

    # Warning modal should be considered only if the ticket state was changed.
    return @submitTimeAccounting(e, ticket, macro, editContollerForm) if not @changed('ticket', 'state_id')

    ticketState    = App.TicketState.find(ticket.state_id)
    isClosed       = ticketState.state_type.name is 'closed'
    isPendingClose = ticketState.state_type.name is 'pending action' && App.TicketState.find(ticketState.next_state_id).state_type.name is 'closed'
    return @submitTimeAccounting(e, ticket, macro, editContollerForm) if !isClosed && !isPendingClose

    checklist = App.Checklist.find ticket.checklist_id
    if !checklist || checklist.open_items().length is 0
      return @submitTimeAccounting(e, ticket, macro, editContollerForm)

    new App.TicketZoomChecklistModal(
      container: @el.closest('.content')
      ticket: ticket
      cancelCallback: =>
        @submitEnable(e)
      submitCallback: =>
        @submitTimeAccounting(e, ticket, macro, editContollerForm)
    )

  submitTimeAccounting: (e, ticket, macro, editContollerForm) =>
    if !ticket.article
      @submitPost(e, ticket, macro)
      return

    # verify if time accounting is enabled
    if !editContollerForm.getFlag('time_accounting')
      @submitPost(e, ticket, macro)
      return

    new App.TicketZoomTimeAccountingModal(
      container: @el.closest('.content')
      ticket: ticket
      cancelCallback: =>
        @submitEnable(e)
      submitCallback: (params) =>
        ticket.article.time_unit              = params.time_unit
        ticket.article.accounted_time_type_id = params.accounted_time_type_id

        @submitPost(e, ticket, macro)
    )

  saveDraft: (e) =>
    e.stopPropagation()
    e.preventDefault()

    params =
      new_article:       @articleNew?.params() || {}
      ticket_attributes: @ticketParams()

    params.new_article.body = App.Utils.signatureRemoveByHtml(params.new_article.body)

    loaded_draft_id = params.new_article.shared_draft_id

    params.form_id = params.new_article['form_id']
    delete params.new_article['form_id']
    delete params.new_article['shared_draft_id']

    sharedDraft = @sharedDraft()

    draftExists = sharedDraft?
    isLoaded = loaded_draft_id == String(sharedDraft?.id)

    matches = draftExists &&
      _.isEqual(sharedDraft.new_article, params.new_article) &&
      _.isEqual(sharedDraft.ticket_attributes, params.ticket_attributes)

    if draftExists && !(isLoaded && matches)
      new App.TicketSharedDraftOverwriteModal(
        onShowDraft: @draft
        onSaveDraft: =>
          @draftSaveToServer(params)
      )

      return

    @draftSaveToServer(params)

  draftSaveToServer: (params) =>
    @draftSaving()

    @ajax
      id: 'ticket_shared_draft_update'
      type: 'PUT'
      url: @apiPath + '/tickets/' + @ticket_id + '/shared_draft'
      processData: true
      data: JSON.stringify(params)
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        App.Event.trigger 'ui::ticket::shared_draft_saved', { ticket_id: @ticket_id, shared_draft_id: data.shared_draft_id }
        @draftFetched()
      error: =>
        @draftFetched()

  submitPost: (e, ticket, macro) =>
    taskAction = @$('.js-secondaryActionButtonLabel').data('type')

    if macro && macro.ux_flow_next_up
      taskAction = macro.ux_flow_next_up

    nextTicket = undefined
    if taskAction is 'closeNextInOverview' || taskAction is 'next_from_overview'
      nextTicket = @getNextTicketInOverview()

    # submit changes
    @ajax(
      id: "ticket_update_#{ticket.id}"
      type: 'PUT'
      url: "#{App.Ticket.url}/#{ticket.id}?all=true"
      data: JSON.stringify(ticket.attributes())
      processData: true
      success: (data) =>

        # reset article - should not be resubmitted on next ticket update
        ticket.article = undefined

        # reset form after save
        @reset()

        @load(data, false, true)

        if @sidebarWidget
          @sidebarWidget.commit()

        if taskAction is 'closeNextInOverview' || taskAction is 'next_from_overview'
          @openTicketInOverview(nextTicket)
          App.Event.trigger('overview:fetch')
          return
        else if taskAction is 'closeTabOnTicketClose' || taskAction is 'next_task_on_close'
          state_type_id = App.TicketState.find(ticket.state_id).state_type_id
          state_type    = App.TicketStateType.find(state_type_id).name
          if state_type is 'closed'
            App.Event.trigger('overview:fetch')
            @taskCloseTicket(true)
            return
        else if taskAction is 'closeTab' || taskAction is 'next_task'
          App.Event.trigger('overview:fetch')
          @taskCloseTicket(true)
          return

        @autosaveStart()
        @muteTask()
        @submitEnable(e)
        @scrollToPosition('bottom', 50)

      error: (settings, details) =>
        error = undefined
        if settings && settings.responseJSON && settings.responseJSON.error
          error = settings.responseJSON.error
        App.Event.trigger 'notify', {
          type:    'error'
          msg:     details.error_human || details.error || error || __('Saving failed.')
          timeout: 2000
        }
        @autosaveStart()
        @muteTask()
        @fetch()
        @submitEnable(e)
    )

  bookmark: (e) ->
    $(e.currentTarget).find('.bookmark.icon').toggleClass('filled')

  draft: (e) =>
    e.preventDefault()

    new App.TicketSharedDraftModal(
      container:    @el.closest('.content')
      hasChanges:   App.TaskManager.worker(@taskKey).changed()
      parent:       @
      shared_draft: @sharedDraft()
    )

  fetchDraft: ->
    @ajax(
      id:    "ticket_#{@ticket_id}_shared_draft"
      type: 'GET'
      url:    "#{@apiPath}/tickets/#{@ticket_id}/shared_draft"
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @draftFetched()
    )

  draftSaving: ->
    @updateDraftButton(true, 'saving')

  updateDraftButton: (visible, state) ->
    button = @el.find('.js-draft')

    button.toggleClass('hide', !visible)
    button.find('.attributeBar-draft--available').toggleClass('hide', state != 'available')
    button.find('.attributeBar-draft--saving').toggleClass('hide', state != 'saving')
    button.attr('disabled', state == 'saving')

    @el.find('.js-dropdownActionSaveDraft').attr('disabled', state == 'saving')

  draftFetched: ->
    @updateDraftButton(@sharedDraft()?, 'available')

  draftState: ->
    @sharedDraft()?

  sharedDraft: ->
    App.TicketSharedDraftZoom.findByAttribute 'ticket_id', @ticket_id

  reset: (e) =>
    if e
      e.preventDefault()

    # reset task
    @taskReset()

    # reset default follow-up state
    @resetDefaultFollowUpState()

    # reset/delete uploaded attachments
    App.Ajax.request(
      type:  'DELETE'
      url:   "#{App.Config.get('api_path')}/upload_caches/#{@form_id}"
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

    # Set the article type_id if the type is set.
    if @localTaskData.article && @localTaskData.article.type && !@localTaskData.article.type_id
      @localTaskData.article.type_id = App.TicketArticleType.findByAttribute('name', @localTaskData.article.type).id

    if @localTaskData.form_id
      if !@localTaskData.article
        @localTaskData.article = {}
      @localTaskData.article.form_id = @localTaskData.form_id

    # Remove inline images.
    if _.isObject(@localTaskData.article) && _.isArray(App.TaskManager.get(@taskKey).attachments)
      @localTaskData.article['attachments'] = _.filter( App.TaskManager.get(@taskKey).attachments, (attachment) ->
        return if attachment.preferences && attachment.preferences['Content-Disposition'] is 'inline'
        return attachment
      )

    if area
      if !@localTaskData[area]
        @localTaskData[area] = {}
      return @localTaskData[area]
    if !@localTaskData
      @localTaskData = {}
    @localTaskData

  taskUpdate: (area, data) =>
    @localTaskData[area] = data

    # Set the article type if the type_id is set.
    if @localTaskData[area]['type_id'] && !@localTaskData[area]['type']
      @localTaskData[area]['type'] = App.TicketArticleType.find(@localTaskData[area]['type_id']).name

    taskData = { 'state': @localTaskData }
    if _.isArray(data.attachments)
      taskData.attachments = data.attachments

    App.TaskManager.update(@taskKey, taskData)

  taskUpdateAttachments: (area, attachments) =>
    taskData = App.TaskManager.get(@taskKey)
    return if !taskData

    taskData.attachments = attachments
    App.TaskManager.update(@taskKey, taskData)

  taskUpdateAll: (data) =>
    @localTaskData = data
    @localTaskData.article['form_id'] = @form_id

    # Set the article type if the type_id is set.
    if @localTaskData.article['type_id'] && !@localTaskData.article['type']
      @localTaskData.article['type'] = App.TicketArticleType.find(@localTaskData.article['type_id']).name

    taskData = { 'state': @localTaskData }
    if _.isArray(data.attachments)
      taskData.attachments = data.attachments

    App.TaskManager.update(@taskKey, taskData)

  # reset task state
  taskReset: =>
    @form_id = App.ControllerForm.formId()

    if @articleNew
      @articleNew.form_id = @form_id
      @articleNew.render()

    @articleView.updateFormId(@form_id)

    @localTaskData =
      ticket:  {}
      article: {}
    App.TaskManager.update(@taskKey, { 'state': @localTaskData, attachments: [] })

  renderOverviewNavigator: (parentEl) ->
    @overviewNavigatorController?.releaseController()
    @overviewNavigatorController = new App.TicketZoomOverviewNavigator(
      el:          parentEl.find('.js-overviewNavigatorContainer')
      ticket_id:   @ticket_id
      overview_id: @overview_id
    )

  copyTicketNumber: =>
    text = @el.find('.js-objectNumber').first().data('number') || ''
    if text
      @tooltipCopied = @copyToClipboardWithTooltip(text, '.ticket-number-copy-header', 'body')

  hideCopyTicketNumberTooltip: =>
    return if !@tooltipCopied
    @tooltipCopied.tooltip('hide')

class TicketZoomRouter extends App.ControllerPermanent
  @requiredPermission: ['ticket.agent', 'ticket.customer']
  constructor: (params) ->
    super

    # check authentication
    @authenticateCheckRedirect()

    return @byNumber(params) if params.ticket_number
    @byTicketId(params)

  byNumber: (params) ->
    return @byTicketId(params) if !params.ticket_number
    return @byTicketId(params) if params.ticket_id

    number = params.ticket_number
    delete params.ticket_number

    ticket = App.Ticket.findByAttribute('number', number)
    return @navigate("ticket/zoom/#{ticket.id}") if ticket

    App.Ajax.request(
      type:  'POST'
      url:   "#{@apiPath}/tickets/search?full=true"
      processData: true
      data: JSON.stringify(
        condition: {
          'ticket.number': {
            operator: 'is',
            value: number
          }
        }
        limit: 1
      )
      success: (data, status, xhr) =>
        return @byTicketId(params) if _.isEmpty(data.record_ids)
        @navigate("ticket/zoom/#{data.record_ids[0]}")
      error: =>
        @byTicketId(params)
    )

  byTicketId: (params) ->

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

App.Config.set('ticket/zoom/number/:ticket_number', TicketZoomRouter, 'Routes')
App.Config.set('ticket/zoom/:ticket_id', TicketZoomRouter, 'Routes')
App.Config.set('ticket/zoom/:ticket_id/nav/:nav', TicketZoomRouter, 'Routes')
App.Config.set('ticket/zoom/:ticket_id/:article_id', TicketZoomRouter, 'Routes')

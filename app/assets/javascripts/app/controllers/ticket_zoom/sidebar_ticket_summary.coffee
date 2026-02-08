class App.SidebarTicketSummary extends App.Controller
  DISPLAY_STRUCTURE: [
    { key: 'customer_request', name: __('Customer Intent'), value: 'customer_request' },
    { key: 'conversation_summary', name: __('Conversation Summary'), value: 'conversation_summary', type: 'paragraphs' },
    { key: 'open_questions', name: __('Open Questions'), value: 'open_questions', type: 'list' },
    { key: 'upcoming_events', name: __('Upcoming Events'), value: 'upcoming_events', type: 'list' },
    { key: 'customer_sentiment', name: __('Customer Sentiment'), value: ['customer_emotion', 'customer_mood'] },
  ]

  constructor: ->
    super

    @controllerBind('config_update', @configHasChanged)

    return if !@parent?.activeState

    @ticketZoomShown()

  activateSummary: =>
    return if @summaryActivated

    @summaryActivated = true

    @loadSummarization()

    # prepopulate already summarized article IDs
    @summaryReloadNeeded()

    # load new summary if it has changed
    @controllerBind('ticket::summary::update', (data) =>
      return if !@sidebarIsEnabled()
      return if data.ticket_id.toString() isnt @ticket.id.toString()
      return if data.locale isnt App.i18n.get() && !data.error

      if data.error
        if data.ai_analytics_run_id
          @loadSummarization(null, data.ai_analytics_run_id)
        else
          @renderSummarization(error: true)

        return

      if !@isLoadSummaryNow()
        @waitingSummarization = true
        return

      @loadSummarization()
    )

    # check if new summary needs to be requested
    @controllerBind('ui::ticket::load', (data) =>
      return if !@sidebarIsEnabled()
      return if data.ticket_id.toString() isnt @ticket.id.toString()
      return if !@summaryReloadNeeded()
      return if !@isLoadSummaryNow()

      @loadSummarization()
    )

  isLoadSummaryNow: =>
    if @summarizeOnTicketShow()
      !!@parent?.activeState
    else
      @parent?.activeState && @isVisible()

  isVisible: =>
    @parentSidebar?.currentTab == @sidebarItem()?.name

  ticketZoomShown: =>
    return if !@sidebarIsEnabled()

    if @summaryActivated
      if @waitingSummarization && @isLoadSummaryNow()
        @loadSummarization()
      return

    return if !@summarizeOnTicketShow()
    @activateSummary()

  configHasChangedLoadSummary: =>
    return if !@sidebarIsEnabled()

    if !@isLoadSummaryNow()
      @waitingSummarization = true
      return

    @loadSummarization()

  summarizeOnTicketShow: =>
    # Ticket object may have old group contents cached in some cases
    # Load group object directly to make sure it's up to date
    groupSetting = App.Group.find(@ticket.group_id)?.summary_generation

    switch groupSetting
      when 'on_ticket_detail_opening'
        true
      when 'on_ticket_summary_sidebar_activation'
        false
      else
        setting = App.Config.get('ai_assistance_ticket_summary_config') || {}
        setting['generate_on'] != 'on_ticket_summary_sidebar_activation'

  sidebarItem: =>
    return if !@sidebarIsEnabled()

    {
      name:           'summary'
      badgeIcon:      'smart-assist'
      badgeCallback:  @badgeRender
      sidebarHead:     __('AI Summary')
      sidebarCallback: @sidebarCallback
      sidebarActions:  []
    }

  badgeDetails: =>
    {
      name:       'summary'
      icon:       'smart-assist'
      dotVisible: @sidebarItem()?.name isnt @parentSidebar.currentTab and not @isPreparingData && @summaryData?.analytics?.is_unread
    }

  badgeRender: (el) =>
    @badgeEl = el
    @badgeRenderLocal()

  badgeRenderLocal: =>
    return if !@badgeEl
    @badgeEl.html(App.view('generic/sidebar_tabs_item')(@badgeDetails()))

  markAsRead: =>
    @summaryData?.analytics?.is_unread = false
    @badgeRenderLocal()
    @feedbackWidget?.recordUsage({}, null, =>
      @hasUsage = false
      @notify(
        type: 'error'
        msg:  __('Your AI result usage could not be recorded.')
      )
      false
    )
    @hasUsage = true

  shown: =>
    if not @isPreparingData and not @hasUsage
      @markAsRead()
    else
      @badgeRenderLocal()

    if @summaryActivated
      if @waitingSummarization && !@summarizeOnTicketShow()
        @loadSummarization()
      return

    @activateSummary()

  sidebarIsEnabled: =>
    return false if !App.Config.get('ai_provider')
    return false if !App.Config.get('ai_assistance_ticket_summary')
    return false if !(@ticket and @ticket.currentView() is 'agent')
    return false if @ticket.state.state_type.name is 'merged'

    true

  sidebarCallback: (el) =>
    @elSidebar = el

  configHasChanged: (config) =>
    switch config.name
      when 'ai_assistance_ticket_summary'
        App.Event.trigger('ui::ticket::sidebarRerender', { taskKey: @taskKey })
      when 'ai_assistance_ticket_summary_config'
        @configHasChangedLoadSummary()

  getAvailableDisplayStructure: ->
    config = App.Config.get('ai_assistance_ticket_summary_config')
    @DISPLAY_STRUCTURE.filter((item) -> !(item.key of config) or config[item.key] is true)

  renderSummarization: (data) =>
    @summaryData = data if data
    @badgeRenderLocal()

    return if !@elSidebar

    summarization = $(App.view('ticket_zoom/sidebar_ticket_summary')(
      data:      @summaryData
      structure: @getAvailableDisplayStructure()
    ))

    summarization
      .on('click', '.js-retry', @retrySummarization)

    @stopStripeAnimation() if not @isSummarizationLoading()

    @feedbackWidget = new App.AIFeedbackWidget(
      el:                  summarization.find('.js-aiFeedback')
      runId:               @summaryData?.analytics?.run_id
      hasProvidedFeedback: @summaryData?.analytics?.usage?.user_has_provided_feedback
      regenerateCallback:  @loadSummarization
    )

    @hasUsage = not _.isNull(@summaryData?.analytics?.usage)
    @markAsRead() if @sidebarItem()?.name is @parentSidebar.currentTab and not @hasUsage

    @elSidebar.html(summarization)

  isSummarizationLoading: =>
    not @summaryData?.error and App.Config.get('ai_provider') and not @summaryData?.result

  retrySummarization: (e) =>
    @preventDefaultAndStopPropagation(e)
    @renderSummarization({})
    @loadSummarization()

  summaryReloadNeeded: =>
    ticket = App.Ticket.find(@ticket.id)
    ticketSummarizableArticleIds = @getTicketSummarizableArticleIds(ticket.article_ids)

    if @ticketSummarizableArticleIds && _.isEqual(@ticketSummarizableArticleIds, ticketSummarizableArticleIds)
      return false

    @ticketSummarizableArticleIds = ticketSummarizableArticleIds
    true

  getTicketSummarizableArticleIds: (allArticleIds) ->
    allArticleIds.filter (elem) ->
      article = App.TicketArticle.find(elem)
      sender  = App.TicketArticleSender.find(article.sender_id)

      sender.name != 'System' && article.body?.length > 0

  loadSummarization: (regenerationOfId = null, ai_analytics_run_id = null) =>
    return if !@sidebarIsEnabled()

    @waitingSummarization = false

    data = {}

    data.regeneration_of_id = regenerationOfId if regenerationOfId
    data.ai_analytics_run_error_id = ai_analytics_run_id if ai_analytics_run_id

    @startStripeAnimation()

    @ajax(
      id:             "ticket-summarization-#{@taskKey}"
      type:           'POST'
      url:            "#{@apiPath}/tickets/#{@ticket.id}/summarize"
      data:           JSON.stringify(data)
      preprocessData: true
      success: (data, status, xhr) =>
        @renderSummarization(data)

      error: (xhr, status, error) ->
        # show error toaster
    )

  startStripeAnimation: =>
    @elSidebar?.parent()
      .find('hr')
      .addClass('animate')

  stopStripeAnimation: =>
    @elSidebar?.parent()
      .find('hr')
      .removeClass('animate')

App.Config.set('350-TicketSummary', App.SidebarTicketSummary, 'TicketZoomSidebar')

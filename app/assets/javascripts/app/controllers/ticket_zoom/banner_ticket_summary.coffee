class App.TicketZoomBannerTicketSummary extends App.Controller
  events:
    'click .js-hideBanner': 'hideBanner'
    'click .js-seeSummary': 'openSummaryTab'

  constructor: ->
    super

    @controllerBind('config_update', @configHasChanged)

    return if !@bannerIsEnabled()

    @render()

    # rerender if current user has been updated
    @listenTo(App.User.current(), 'refresh', => @render())

    # hide banner if summary sidebar is shown
    @controllerBind('ui::ticket::summarySidebar::shown', (data) =>
      return if data.ticket_id isnt @ticket.id
      return if !@isBannerVisible()

      @hideOnSummaryTabOpen()
    )

    # show banner if new summary is available
    @controllerBind('ui::ticket::summaryUpdate', (data) =>
      return if data.ticket_id isnt @ticket.id

      @isPreparingData = (_.isNull(data?.result) or data?.error)
      @fingerprintMD5  = data?.result?.fingerprint_md5

      @render()
    )

  render: =>
    if !@isBannerVisible()
      @html('')
      return

    @html App.view('ticket_zoom/banner_ticket_summary')(
      isPreparingData: @isPreparingData
    )

  configHasChanged: (config) =>
    return if config.name isnt 'ai_assistance_ticket_summary'
    return @html('') if config.value isnt true

    @render()

  bannerIsEnabled: =>
    return false if !App.Config.get('ai_provider')
    return false if !App.Config.get('ai_assistance_ticket_summary')
    return false if !(@ticket and @ticket.currentView() is 'agent')
    return false if @ticket.state.state_type.name is 'merged'

    true

  hideBanner: (e) =>
    @preventDefaultAndStopPropagation(e)

    new App.ControllerConfirm(
      head:  __('Hide Smart Assist Summary Banner?')
      message: __('You can re-enable it anytime in Profile Settings > Appearance.')
      buttonSubmit: __('Yes, hide it')
      callback: @doHide
    )

  doHide: =>
    @el.hide()

    @ajax(
      id:          'preferences'
      type:        'PUT'
      url:         "#{@apiPath}/users/preferences"
      data:        JSON.stringify(ticket_summary_banner_hidden: true)
      processData: true
    )

  openSummaryTab: (e) =>
    @preventDefaultAndStopPropagation(e)

    @hideOnSummaryTabOpen()

    @el
      .closest('.content')
      .find(".tabsSidebar-tab[data-tab='summary']:not(.active)")
      .click()

  bannerLocalStorageKey: =>
    "#{@ticket.id}-ticket-summary-banner-seen"

  isBannerVisible: =>
    return false if App.User.current()?.preferences?.ticket_summary_banner_hidden
    return false if App.LocalStorage.get(@bannerLocalStorageKey()) is @fingerprintMD5
    true

  hideOnSummaryTabOpen: =>

    # Do not remember hiding of the banner if the data is still being prepared or the fingerprint is missing.
    return if @isPreparingData || !@fingerprintMD5

    App.LocalStorage.set(@bannerLocalStorageKey(), @fingerprintMD5)
    @render()

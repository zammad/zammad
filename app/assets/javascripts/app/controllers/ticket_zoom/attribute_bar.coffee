class App.TicketZoomAttributeBar extends App.Controller
  elements:
    '.js-submitDropdown': 'buttonDropdown'
    '.js-reset':          'resetButton'

  events:
    'mousedown .js-openDropdownMacro':    'toggleMacroMenu'
    'click .js-openDropdownMacro':        'preventDefaultAndStopPropagation'
    'mouseup .js-dropdownActionMacro':    'performTicketMacro'
    'mouseenter .js-dropdownActionMacro': 'onActionMacroMouseEnter'
    'mouseleave .js-dropdownActionMacro': 'onActionMacroMouseLeave'
    'mouseup .js-dropdownActionSaveDraft': 'saveDraft'
    'mouseenter .js-dropdownActionSaveDraft': 'onActionMacroMouseEnter'
    'mouseleave .js-dropdownActionSaveDraft': 'onActionMacroMouseLeave'
    'click .js-secondaryAction':          'chooseSecondaryAction'

  searchCondition: {}
  constructor: ->
    super

    @subscribeId = App.Macro.subscribe(@checkMacroChanges)
    @render()

    # rerender, e. g. on language change
    @controllerBind('ui:rerender', =>
      @render()
    )

    @controllerBind('MacroPreconditionUpdate', (data) =>
      return if data.taskKey isnt @taskKey
      @searchCondition = data.params
      @render()
    )

    @controllerBind('ui::ticket::updateSharedDraft', (data) =>
      return if data.taskKey isnt @taskKey
      @render(data)
    )

    @listenTo(App.Group, 'refresh', (refreshed_group) =>
      selected_group_id = @el.closest('.content').find('[name=group_id]').val()
      selected_group    = App.Group.find selected_group_id

      return if !selected_group
      return if !refreshed_group
      return if refreshed_group.id != selected_group.id

      return if @sharedDraftsEnabled == selected_group.shared_drafts

      @render({ newGroupId: selected_group.id })
    )

  getAction: ->
    return App.Session.get().preferences.secondaryAction || App.Config.get('ticket_secondary_action') || 'stayOnTab'

  release: =>
    App.Macro.unsubscribe(@subscribeId)

  render: (options = {}) =>
    # remember current reset state
    resetButtonShown = false
    if @resetButton.get(0) && !@resetButton.hasClass('hide') && @ticket.editable()
      resetButtonShown = true

    group                  = App.Group.find options?.newGroupId || @ticket.group_id
    draft                  = App.TicketSharedDraftZoom.findByAttribute 'ticket_id', @ticket.id
    accessibleGroups       = App.User.current().allGroupIds('change')
    sharedDraftButtonShown = group?.shared_drafts && _.contains(accessibleGroups, String(group.id))
    sharedDraftsEnabled    = group?.shared_drafts && _.contains(accessibleGroups, String(group.id))
    sharedButtonVisible    = sharedDraftsEnabled && draft? && @ticket.editable()

    @sharedDraftsEnabled = sharedDraftsEnabled

    macros = App.Macro.getList()

    @macroLastUpdated = App.Macro.lastUpdatedAt()
    @possibleMacros   = []

    if _.isEmpty(macros) || @ticket.currentView() is 'customer'
      macroDisabled = true
    else
      for macro in macros
        if !_.isEmpty(macro.group_ids) && @searchCondition.group_id && !_.includes(macro.group_ids, parseInt(@searchCondition.group_id))
          continue

        @possibleMacros.push macro

    localeEl = $(App.view('ticket_zoom/attribute_bar')(
      ticket:                 @ticket
      macros:                 @possibleMacros
      macroDisabled:          macroDisabled
      sharedButtonVisible:    sharedButtonVisible
      sharedDraftsDisabled:   !sharedDraftsEnabled
      overview_id:            @overview_id
      resetButtonShown:       resetButtonShown
      sharedDraftButtonShown: sharedDraftButtonShown
    ))

    @setSecondaryAction(@getAction(), localeEl)

    if @ticket.currentView() is 'agent'
      @taskbarWatcher = new App.TaskbarWatcher(
        taskKey: @taskKey
        el:      localeEl.filter('.js-avatars')
      )

    @html localeEl

    @el.find('.js-draft').popover(
      trigger:   'hover'
      container: 'body'
      html:      true
      animation: false
      delay:     100
      placement: 'auto'
      sanitize:  false
      content:   =>
        draft     = App.TicketSharedDraftZoom.findByAttribute 'ticket_id', @ticket?.id
        timestamp = App.ViewHelpers.humanTime(draft?.updated_at)
        user      = App.User.find draft?.updated_by_id
        name      = user?.displayName()

        content =  App.i18n.translatePlain('Last change %s %s by %s', timestamp, '<br>', name)

        # needs linebreak to align vertically without title
        '<br>' + content
    )

  start: =>
    return if !@taskbarWatcher
    @taskbarWatcher.start()
    @setSecondaryAction(@getAction(), @el)

  stop: =>
    return if !@taskbarWatcher
    @taskbarWatcher.stop()

  checkMacroChanges: =>
    macroLastUpdated = App.Macro.lastUpdatedAt()
    return if macroLastUpdated is @macroLastUpdated
    @render()

  toggleMacroMenu: =>
    if @buttonDropdown.hasClass('is-open')
      @closeMacroMenu()
      return
    @openMacroMenu()

  openMacroMenu: =>
    @buttonDropdown.addClass 'is-open'
    $(document).on 'click.buttonDropdown', @closeMacroMenu

  closeMacroMenu: =>
    @buttonDropdown.removeClass 'is-open'
    $(document).off 'click.buttonDropdown'

  performTicketMacro: (e) =>
    macroId = $(e.currentTarget).data('id')
    macro = App.Macro.find(macroId)

    @macroCallback(e, macro)
    @closeMacroMenu()

  saveDraft: (e) =>
    @draftCallback(e)

  onActionMacroMouseEnter: (e) =>
    @$(e.currentTarget).addClass('is-active')

  onActionMacroMouseLeave: (e) =>
    @$(e.currentTarget).removeClass('is-active')

  chooseSecondaryAction: (e) =>
    type = $(e.currentTarget).find('.js-secondaryActionLabel').data('type')
    @setSecondaryAction(type, @el)
    @setUserPreferencesSecondaryAction(type)

  setSecondaryAction: (type, localEl) ->
    element = localEl.find(".js-secondaryActionLabel[data-type=#{type}]")
    return @setSecondaryAction('stayOnTab', localEl) if element.length == 0
    text = element.text()
    localEl.find('.js-secondaryAction .js-selectedIcon.is-selected').removeClass('is-selected')
    element.closest('.js-secondaryAction').find('.js-selectedIcon').addClass('is-selected')
    localEl.find('.js-secondaryActionButtonLabel').text(text)
    localEl.find('.js-secondaryActionButtonLabel').data('type', type)

  setUserPreferencesSecondaryAction: (type) ->
    session = App.Session.get()
    return if session.preferences.secondaryAction is type
    session.preferences.secondaryAction = type

    @ajax(
      id:          'setUserPreferencesSecondaryAction'
      type:        'PUT'
      url:         "#{App.Config.get('api_path')}/users/preferences"
      data:        JSON.stringify(secondaryAction: type)
      processData: true
    )

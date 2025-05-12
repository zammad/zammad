class SidebarChecklist extends App.Controller
  constructor: ->
    super
    @changeable = @ticket.userGroupAccess('change')

    @controllerBind('ui::ticket::checklistSidebar::showLoader', =>
      @widget.showLoader() if typeof @widget?.showLoader is 'function'
    )

    @controllerBind('config_update', @configHasChanged)

  release: =>
    super
    @unsubscribe()

  sidebarItem: =>
    return if !App.Config.get('checklist')
    return if @ticket.currentView() != 'agent'

    @item = {
      name: 'checklist'
      badgeCallback: @badgeRender
      sidebarHead: __('Checklist')
      sidebarCallback: @showChecklist
      sidebarActions: @sidebarActions()
    }

  sidebarActions: =>
    result = []

    if @checklist and @changeable
      result.push({
        title:    __('Rename checklist')
        name:     'checklist-rename'
        callback: @renameChecklist
      },
      {
        title:    __('Remove checklist')
        name:     'checklist-remove'
        callback: @removeChecklist
      })

    result

  configHasChanged: (config) =>
    return if config.name isnt 'checklist'

    App.Event.trigger('ui::ticket::sidebarRerender', { taskKey: @taskKey })

  renameChecklist: =>
    @widget?.onTitleChange()

  removeChecklist: =>
    new ChecklistRemoveModal(
      container: @elSidebar.closest('.content')
      callback:  =>
        @checklist.destroy(
          done: =>
            @widget = new App.SidebarChecklistStart(el: @elSidebar, parentVC: @)
        )
    )

  renderActions: =>
    @parentSidebar.sidebarActionsRender('checklist', @sidebarActions())

  subscribe: =>
    @unsubscribe()

    @controllerBind('ui::ticket::all::loaded', @updateOnTicketAllLoaded)

    # Exit early and subscribe only to the ticket when sidebar is not opened
    return if !(@widget instanceof App.SidebarChecklistShow)
    # Keep going and subscribe to checklist items and tickets in there when sidebar is opened

    # checklist subscriptions
    checklist = App.Checklist.find @ticket.checklist_id
    return if !checklist

    for id in checklist.item_ids
      item = App.ChecklistItem.find(id)
      continue if !item
      continue if !item.ticket_id

      sid = App.Ticket.subscribeItem(
        item.ticket_id,
        (item) =>
          @renderWidget()
      )
      @subscriptions.push(
        object: 'Ticket',
        id: item.ticket_id,
        sid: sid,
      )

  unsubscribe: =>
    @subscriptions ||= []

    for entry in @subscriptions
      App[entry.object].unsubscribeItem(entry.id, entry.sid)

    @subscriptions = []

    @controllerUnbind('ui::ticket::all::loaded', @updateOnTicketAllLoaded)

  updateOnTicketAllLoaded: (data) =>
    return if data.ticket_id.toString() isnt @ticket.id.toString()

    @badgeRenderLocal()
    @renderWidget()

  showChecklist: (el) =>
    @elSidebar = el
    @startLoading()

  shown: (enterEditMode = false) =>
    @startLoading()

    if !@ticket.checklist_id
      @renderWidget()
      return

    @ajax(
      id:   "checklist_ticket#{@ticket.id}"
      type: 'GET'
      url:  "#{@apiPath}/checklists/#{@ticket.checklist_id}"
      processData: true
      success: (data, status, xhr) =>
        @stopLoading()

        App.Collection.loadAssets(data.assets)

        @delay => @renderWidget(enterEditMode)
    )

  renderWidget: (enterEditMode = false) =>
    @checklist = App.Checklist.find(@ticket.checklist_id)

    if @checklist
      if @widget instanceof App.SidebarChecklistShow and @checklist?.id is @widget.checklist?.id
        @widget.checklist = @checklist
        @widget.renderTable()
      else
        @widget?.releaseController()
        @widget = new App.SidebarChecklistShow(el: @elSidebar, parentVC: @, checklist: @checklist, readOnly: !@changeable, enterEditMode: enterEditMode)
    else if !(@widget instanceof App.SidebarChecklistStart)
      @widget?.releaseController()
      @widget = new App.SidebarChecklistStart(el: @elSidebar, parentVC: @, readOnly: !@changeable)

    @subscribe()

    @renderActions()
    @badgeRenderLocal()

  metaBadge: =>
    checklist = App.Checklist.find @ticket.checklist_id

    {
      name: 'checklist'
      icon: 'checklist'
      counterPossible: true
      counter: checklist?.open_items().length
    }

  badgeRender: (el) =>
    @badgeEl = el
    @badgeRenderLocal()

  badgeRenderLocal: =>
    return if !@badgeEl
    @badgeEl.html(App.view('generic/sidebar_tabs_item')(@metaBadge()))

    return if @badgeRenderLocalInit
    @badgeRenderLocalInit = true
    @subscribe()

class ChecklistRemoveModal extends App.ControllerGenericDestroyConfirm
  onSubmit: =>
    @close()
    @callback()


App.Config.set('600-Checklist', SidebarChecklist, 'TicketZoomSidebar')

class SidebarChecklist extends App.Controller
  constructor: ->
    super

    @changeable = @ticket.userGroupAccess('change')

  release: =>
    super
    @unsubscribe()
    @clearWidget()

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

  renameChecklist: =>
    @widget?.onTitleChange()

  removeChecklist: =>
    new ChecklistRemoveModal(
      container: @elSidebar.closest('.content')
      callback:  =>
        @checklist.destroy(
          done: =>
            @clearWidget()

            @widget = new App.SidebarChecklistStart(el: @elSidebar, parentVC: @)
        )
    )

  renderActions: =>
    @parentSidebar.sidebarActionsRender('checklist', @sidebarActions())

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
          return if @widget?.actionController
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
    return if @ticket.updated_by_id is App.Session.get().id

    @renderWidget() if !@widget?.actionController

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
    @clearWidget()

    @checklist = App.Checklist.find(@ticket.checklist_id)

    if @checklist
      @widget = new App.SidebarChecklistShow(el: @elSidebar, parentVC: @, checklist: @checklist, readOnly: !@changeable, enterEditMode: enterEditMode)
    else
      @widget = new App.SidebarChecklistStart(el: @elSidebar, parentVC: @, readOnly: !@changeable)

    @subscribe()

    @renderActions()
    @badgeRenderLocal()

  clearWidget: =>
    @widget?.el.empty()
    @widget?.releaseController()

    @checklist = undefined
    @renderActions()

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

class SidebarChecklist extends App.Controller
  constructor: ->
    super

    @changeable = @ticket.userGroupAccess('change')
    @counter = @ticket.checklist_incomplete_items

  release: =>
    super
    if @badgeSubscribeId
      @ticket.unsubscribe(@badgeSubscribeId)
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
    @subscriptions ||= []

    @unsubscribe()

    # catch latest state
    checklist = App.Checklist.find(@checklist.id)

    sid = App.Checklist.subscribeItem(
      checklist.id,
      (item) =>
        return if item.updated_by_id is App.Session.get().id
        return if @widget?.actionController
        @shown()
    )
    @subscriptions.push(
      object: 'Checklist',
      id: checklist.id,
      sid: sid,
    )

    for id in checklist.item_ids
      item = App.ChecklistItem.find(id)
      continue if !item
      continue if !item.ticket_id

      sid = App.Ticket.subscribeItem(
        item.ticket_id,
        (item) =>
          return if @widget?.actionController
          @shown()
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

  showChecklist: (el) =>
    @elSidebar = el
    @startLoading()

  shown: (enterEditMode = false) =>
    @startLoading()

    @ajax(
      id:   'checklist_ticket'
      type: 'GET'
      url:  "#{@apiPath}/tickets/#{@ticket.id}/checklist"
      processData: true
      success: (data, status, xhr) =>
        @clearWidget()
        @stopLoading()

        if data.id
          App.Collection.loadAssets(data.assets)

          @checklist = App.Checklist.find(data.id)
          @counter = @ticket.checklist_incomplete_items

          @widget = new App.SidebarChecklistShow(el: @elSidebar, parentVC: @, checklist: @checklist, readOnly: !@changeable, enterEditMode: enterEditMode)

          @subscribe()
        else
          @widget = new App.SidebarChecklistStart(el: @elSidebar, parentVC: @, readOnly: !@changeable)

        @renderActions()
        @badgeRenderLocal()
    )

    return if @subcribed
    @subcribed = true

    @controllerBind('Checklist:create Checklist:destroy', (data) =>
      return if @ticket_id && @ticket_id isnt data.ticket_id
      return if @widget?.actionController
      @shown()
    )

  clearWidget: =>
    @widget?.el.empty()
    @widget?.releaseController()

    @checklist = undefined
    @counter = 0
    @renderActions()

  metaBadge: =>
    {
      name: 'checklist'
      icon: 'checklist'
      counterPossible: true
      counter: @counter
    }

  badgeRender: (el) =>
    @badgeEl = el
    @badgeRenderLocal()

  badgeRenderLocal: =>
    return if !@badgeEl
    @badgeEl.html(App.view('generic/sidebar_tabs_item')(@metaBadge()))

    return if @badgeSubscribe
    @badgeSubscribe   = true
    @badgeSubscribeId = @ticket.subscribe((ticket) =>
      @counter = ticket.checklist_incomplete_items
      @badgeRenderLocal()
    )

  increaseCounter: =>
    @counter++
    @badgeRenderLocal()

  decreaseCounter: =>
    @counter--
    @badgeRenderLocal()

class ChecklistRemoveModal extends App.ControllerGenericDestroyConfirm
  onSubmit: =>
    @close()
    @callback()


App.Config.set('600-Checklist', SidebarChecklist, 'TicketZoomSidebar')

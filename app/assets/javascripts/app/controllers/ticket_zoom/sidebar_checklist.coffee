class SidebarChecklist extends App.Controller
  constructor: ->
    super

    @changeable = @ticket.userGroupAccess('change')

  release: =>
    super
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
        @ajax(
          id:   'checklist_ticket_remove_checklist'
          type: 'DELETE'
          url:  "#{@apiPath}/tickets/#{@ticket.id}/checklist"
          processData: true
          success: (data, status, xhr) =>
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
      badgeIcon: 'checklist'
      sidebarHead: __('Checklist')
      sidebarCallback: @showChecklist
      sidebarActions: @sidebarActions()
    }

  showChecklist: (el) =>
    @elSidebar = el

    @startLoading()

  delayedShown: =>
    @delay(@shown, 250, 'sidebar-checklist')

  shown: =>
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

          @widget = new App.SidebarChecklistShow(el: @elSidebar, parentVC: @, checklist: @checklist, readOnly: !@changeable, enterEditMode: false)
        else
          @widget = new App.SidebarChecklistStart(el: @elSidebar, parentVC: @, readOnly: !@changeable)

        @renderActions()
    )

    return if @subcribed
    @subcribed = true
    @controllerBind('Checklist:destroy', (data) =>
      return if @ticket_id && @ticket_id isnt data.ticket_id
      @delayedShown()
    )
    @controllerBind('Checklist:create Checklist:update Checklist:touch ChecklistItem:create ChecklistItem:update ChecklistItem:touch ChecklistItem:destroy', (data) =>
      return if @ticket_id && @ticket_id isnt data.ticket_id
      return if data.updated_by_id is App.Session.get().id
      return if @widget?.itemEditInProgress
      return if @widget?.titleChangeInProgress
      @delayedShown()
    )

  clearWidget: =>
    @widget?.el.empty()
    @widget?.releaseController()

    @checklist = undefined
    @renderActions()

  switchToChecklist: (id, enterEditMode = false) =>
    @clearWidget()

    @checklist = App.Checklist.find(id)

    @renderActions()

    @widget = new App.SidebarChecklistShow(el: @elSidebar, parentVC: @, checklist: @checklist, enterEditMode: enterEditMode)

class ChecklistRemoveModal extends App.ControllerGenericDestroyConfirm
  onSubmit: =>
    @close()
    @callback()


App.Config.set('600-Checklist', SidebarChecklist, 'TicketZoomSidebar')

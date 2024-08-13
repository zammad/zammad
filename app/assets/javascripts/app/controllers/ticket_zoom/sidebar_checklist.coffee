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
      badgeIcon: 'checklist'
      sidebarHead: __('Checklist')
      sidebarCallback: @showChecklist
      sidebarActions: @sidebarActions()
    }

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

          @widget = new App.SidebarChecklistShow(el: @elSidebar, parentVC: @, checklist: @checklist, readOnly: !@changeable, enterEditMode: enterEditMode)

          if @subscribeId
            App.Checklist.unsubscribeItem(@subscribeId)

          @subscribeId = App.Checklist.subscribeItem(
            data.id,
            (item) =>
              return if item.updated_by_id is App.Session.get().id
              return if @widget.actionController
              @shown()
          )
        else
          @widget = new App.SidebarChecklistStart(el: @elSidebar, parentVC: @, readOnly: !@changeable)

        @renderActions()
    )

    return if @subcribed
    @subcribed = true

    @controllerBind('Checklist:create Checklist:destroy', (data) =>
      return if @ticket_id && @ticket_id isnt data.ticket_id
      return if data.updated_by_id is App.Session.get().id
      return if @widget.actionController
      @shown()
    )

  clearWidget: =>
    @widget?.el.empty()
    @widget?.releaseController()

    @checklist = undefined
    @renderActions()

class ChecklistRemoveModal extends App.ControllerGenericDestroyConfirm
  onSubmit: =>
    @close()
    @callback()


App.Config.set('600-Checklist', SidebarChecklist, 'TicketZoomSidebar')

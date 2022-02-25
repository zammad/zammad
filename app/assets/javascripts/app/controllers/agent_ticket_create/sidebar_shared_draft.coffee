class SidebarSharedDraft extends App.Controller
  sidebarItem: =>
    return if !@permissionCheck('ticket.agent')

    group = App.Group.find @params.group_id

    return if !group?.shared_drafts

    @item = {
      name: 'shared_draft'
      badgeIcon: 'note'
      sidebarHead: __('Shared Drafts')
      sidebarActions: []
      sidebarCallback: @showDrafts
    }
    @item

  showDrafts: (el) =>
    @el = el

    # show template UI
    new App.WidgetSharedDraft(
      el:              el
      taskKey:         @taskKey
      group_id:        @params.group_id
      active_draft_id: @params.shared_draft_id
    )

App.Config.set('110-SharedDraft', SidebarSharedDraft, 'TicketCreateSidebar')

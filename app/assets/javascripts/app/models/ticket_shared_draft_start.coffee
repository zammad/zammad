class App.TicketSharedDraftStart extends App.Model
  @configure 'TicketSharedDraftStart', 'name', 'group_id'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/tickets/shared_drafts'

  @needsLoading: true

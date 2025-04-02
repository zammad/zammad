class CollectionAssets extends App.Controller
  constructor: ->
    super

    return if !@authenticateCheck()

    App.Role.subscribe(->)
    App.Group.subscribe(->)
    App.TicketState.subscribe(->)
    App.TicketPriority.subscribe(->)
    if App.Session.get().permission('ticket.agent')
      App.Template.subscribe(->)
      App.ChecklistTemplate.subscribe(->)
      App.TicketSharedDraftStart.subscribe(->)

App.Config.set('collection_assets', CollectionAssets, 'Plugins')

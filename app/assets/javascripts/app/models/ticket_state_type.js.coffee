class App.TicketStateType extends App.Model
  @configure 'TicketStateType', 'name', 'note', 'active'
  @extend Spine.Model.Ajax
  @url: '/ticket_state_types'

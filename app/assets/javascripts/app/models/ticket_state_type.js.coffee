class App.TicketStateType extends App.Model
  @configure 'TicketStateType', 'name', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @api_path + '/ticket_state_types'

class App.TicketState extends App.Model
  @configure 'TicketState', 'name', 'note', 'active'
  @extend Spine.Model.Ajax
  @url: @api_path + '/ticket_states'

class App.TicketTimeAccounting extends App.Model
  @configure 'TicketTimeAccounting', 'ticket_id', 'ticket_article_id', 'time_unit', 'type_id'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/ticket/time_accountings'

class App.TicketArticleSender extends App.Model
  @configure 'TicketArticleSender', 'name', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @api_path + '/ticket_article_senders'

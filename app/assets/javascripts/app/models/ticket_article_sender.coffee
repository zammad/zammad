class App.TicketArticleSender extends App.Model
  @configure 'TicketArticleSender', 'name', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/ticket_article_senders'
  @configure_translate = true
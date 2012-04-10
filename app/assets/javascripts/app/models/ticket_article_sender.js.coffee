class App.TicketArticleSender extends App.Model
  @configure 'TicketArticleSender', 'name'
  @extend Spine.Model.Ajax
  @url: '/ticket_article_senders'

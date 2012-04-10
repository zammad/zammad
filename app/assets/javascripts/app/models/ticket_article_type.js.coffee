class App.TicketArticleType extends App.Model
  @configure 'TicketArticleType', 'name'
  @extend Spine.Model.Ajax
  @url: '/ticket_article_types'

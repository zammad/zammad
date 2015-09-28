class App.TicketArticleType extends App.Model
  @configure 'TicketArticleType', 'name', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/ticket_article_types'
  @configure_translate = true
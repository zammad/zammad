class App.TicketArticleType extends App.Model
  @configure 'TicketArticleType', 'name', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @api_path + '/ticket_article_types'

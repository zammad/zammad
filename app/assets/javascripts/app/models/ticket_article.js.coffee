class App.TicketArticle extends App.Model
  @configure 'TicketArticle', 'from', 'to', 'cc', 'subject', 'body', 'ticket_id', 'ticket_article_type_id', 'ticket_article_sender_id', 'internal', 'in_reply_to', 'form_id', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/ticket_articles'
  @configure_attributes = [
      { name: 'ticket_id',                display: 'TicketID', null: false, readonly: 1, },
      { name: 'from',                     display: 'From',     tag: 'input',    type: 'text', limit: 100, null: false, class: 'span8',  },
      { name: 'to',                       display: 'To',       tag: 'input',    type: 'text', limit: 100, null: true, class: 'span8',  },
      { name: 'cc',                       display: 'Cc',       tag: 'input',    type: 'text', limit: 100, null: true, class: 'span8',  },
      { name: 'subject',                  display: 'Subject',  tag: 'input',    type: 'text', limit: 100, null: true, class: 'span8',  },
      { name: 'body',                     display: 'Text',     tag: 'textarea', rows: 5,      limit: 100, null: false, class: 'span8',  },
      { name: 'ticket_article_type_id',   display: 'Type',     tag: 'select',   multiple: false, null: false, relation: 'TicketArticleType', default: '', class: 'medium' },
      { name: 'ticket_article_sender_id', display: 'Sender',   tag: 'select',   multiple: false, null: false, relation: 'TicketArticleSender', default: '', class: 'medium' },
      { name: 'internal',                 display: 'Visibility', tag: 'radio',  default: false,  null: true, options: { true: 'internal', false: 'public' }, class: 'medium' },
    ]

  uiUrl: ->
    '#ticket/zoom/' + @ticket_id + '/' + @id

  @_fillUp: (data) ->

    # add created & updated
    if data.created_by_id
      data.created_by = App.User.find( data.created_by_id )
    if data.updated_by_id
      data.updated_by = App.User.find( data.updated_by_id )

    # add relations
    data.article_type   = App.TicketArticleType.find( data.ticket_article_type_id )
    data.article_sender = App.TicketArticleSender.find( data.ticket_article_sender_id )

    data


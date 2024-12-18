class App.TicketArticle extends App.Model
  @configure 'TicketArticle', 'from', 'to', 'cc', 'subject', 'body', 'content_type', 'ticket_id', 'type_id', 'sender_id', 'internal', 'in_reply_to', 'form_id', 'subtype', 'time_unit', 'accounted_time_type_id', 'preferences', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/ticket_articles'
  @configure_attributes = [
      { name: 'ticket_id',      display: __('TicketID'),    null: false, readonly: 1, searchable: false },
      { name: 'from',           display: __('From'),        tag: 'input',    type: 'text', limit: 100, null: false },
      { name: 'to',             display: __('To'),          tag: 'input',    type: 'text', limit: 100, null: true },
      { name: 'cc',             display: __('CC'),          tag: 'input',    type: 'text', limit: 100, null: true },
      { name: 'subject',        display: __('Subject'),     tag: 'input',    type: 'text', limit: 100, null: true },
      { name: 'body',           display: __('Text'),        tag: 'textarea', rows: 5,      limit: 100, null: false, searchable: true },
      { name: 'type_id',        display: __('Type'),        tag: 'select',   multiple: false, null: false, relation: 'TicketArticleType', default: '' },
      { name: 'sender_id',      display: __('Sender'),      tag: 'select',   multiple: false, null: false, relation: 'TicketArticleSender', default: '' },
      { name: 'internal',       display: __('Visibility'),  tag: 'radio',  default: false,  null: true, options: { true: 'internal', false: 'public' } },
      { name: 'created_by_id',  display: __('Created by'),  relation: 'User', readonly: 1 },
      { name: 'created_at',     display: __('Created'),     tag: 'datetime', readonly: 1, searchable: true },
      { name: 'updated_by_id',  display: __('Updated by'),  relation: 'User', readonly: 1, searchable: true },
      { name: 'updated_at',     display: __('Updated'),     tag: 'datetime', readonly: 1, searchable: true },
      { name: 'origin_by_id',   display: __('Origin By'),   relation: 'User', readonly: 1 },
    ]

  uiUrl: ->
    '#ticket/zoom/' + @ticket_id + '/' + @id

  objectDisplayName: ->
    'Article'

  displayName: ->
    if @subject
      return @subject
    if App.Ticket.exists(@ticket_id)
      ticket = App.Ticket.findNative(@ticket_id)
    if ticket
      return ticket.title
    '-'

  iconActivity: (user) ->
    return if !user
    ticket = App.Ticket.findNative(@ticket_id)
    if ticket.owner_id == user.id
      return 'important'
    ''

  activityMessage: (item) ->
    return if !item
    return if !item.created_by

    if item.type is 'create'
      return App.i18n.translateContent('%s created article for |%s|', item.created_by.displayName(), item.title)
    else if item.type is 'update'
      return App.i18n.translateContent('%s updated article for |%s|', item.created_by.displayName(), item.title)
    else if item.type is 'update.reaction'
      return App.i18n.translateContent('%s reacted with a %s to message from %s |%s|', item.objectNative.preferences?.whatsapp?.reaction?.author, item.objectNative.preferences?.whatsapp?.reaction?.emoji, item.created_by.displayName(), App.Utils.truncate(item.objectNative.body) or '-')
    return "Unknow action for (#{@objectDisplayName()}/#{item.type}), extend activityMessage() of model."

  @contentAttachments: (article) ->
    return [] if !article
    return [] if !article.attachments
    attachments = []
    for attachment in article.attachments
      if attachment && (!attachment.preferences || attachment.preferences && attachment.preferences['original-format'] isnt true)
        attachments.push attachment
    attachments

  attributes: ->
    attrs = super

    if @shared_draft_id
      attrs.shared_draft_id = @shared_draft_id

    attrs

  recipientName: ->
    format        = App.Config.get('ticket_define_email_from')
    user          = App.User.find((@origin_by_id || @created_by_id))
    ticket        = App.Ticket.find(@ticket_id)
    group         = App.Group.find(ticket.group_id)
    email_address = App.EmailAddress.find(group.email_address_id)
    return if !email_address

    separator = App.Config.get('ticket_define_email_from_separator')
    return email_address.name if (user.id is 1 || format is 'SystemAddressName') && user.permission('ticket.agent')
    return "#{user.firstname} #{user.lastname} #{separator} #{email_address.name}" if format is 'AgentNameSystemAddressName' && user.permission('ticket.agent')
    return "#{user.firstname} #{user.lastname}" # AgentName or customer

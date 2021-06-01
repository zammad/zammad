# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Transaction::SignatureDetection

=begin
  {
    object: 'Ticket',
    type: 'update',
    object_id: 123,
    interface_handle: 'application_server', # application_server|websocket|scheduler
    changes: {
      'attribute1' => [before, now],
      'attribute2' => [before, now],
    },
    created_at: Time.zone.now,
    user_id: 123,
  },
=end

  def initialize(item, params = {})
    @item = item
    @params = params
  end

  def perform

    # return if we run import mode
    return if Setting.get('import_mode')

    return if @item[:type] != 'create'
    return if @item[:object] != 'Ticket'

    ticket = Ticket.lookup(id: @item[:object_id])
    return if !ticket

    article = ticket.articles.first
    return if !article

    # if sender is not customer, do not change anything
    sender = Ticket::Article::Sender.lookup(id: article.sender_id)
    return if !sender
    return if sender['name'] != 'Customer'

    # set email attributes
    type = Ticket::Article::Type.lookup(id: article.type_id)
    return if type['name'] != 'email'

    # update current signature of user id
    ::SignatureDetection.rebuild_user(article.created_by_id)

    # user
    user = User.lookup(id: article.created_by_id)
    return if !user
    return if !user.preferences
    return if !user.preferences[:signature_detection]

    line = ::SignatureDetection.find_signature_line_by_article(
      user,
      article
    )
    article.preferences[:signature_detection] = line
    article.save
  end

end

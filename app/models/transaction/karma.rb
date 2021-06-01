# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Transaction::Karma

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

    user = User.lookup(id: @item[:user_id])

    # ticket
    if @item[:object] == 'Ticket'
      ticket_karma(user)
      ticket_article_karma(user)
    end

    # add tagging (check last action time)
    if @item[:object] == 'Tag'
      tagging(user)
    end

    true
  end

  def ticket_karma(user)
    ticket = Ticket.lookup(id: @item[:object_id])
    return if !ticket

    if @item[:type] == 'create'
      Karma::ActivityLog.add('ticket create', user, 'Ticket', ticket.id)
      return
    end

    if @item[:type] == 'reminder_reached'
      return if ticket.owner_id == 1
      return if ticket.pending_time && ticket.pending_time > Time.zone.now - 2.days

      Karma::ActivityLog.add('ticket reminder overdue (+2 days)', ticket.owner, 'Ticket', ticket.id)
      return
    end

    if @item[:type] == 'escalation'
      return if ticket.owner_id == 1

      Karma::ActivityLog.add('ticket escalated', ticket.owner, 'Ticket', ticket.id)
      return
    end

    return if @item[:type] != 'update'
    return if !@item[:changes]
    return if !@item[:changes]['state_id']

    state_before = Ticket::State.lookup(id: @item[:changes]['state_id'][0])
    state_now = Ticket::State.lookup(id: @item[:changes]['state_id'][1])

    # close
    if state_before.state_type.name != 'closed' && state_now.state_type.name == 'closed'

      # did user send a response to customer before?
      current_time = @item[:created_at]
      ticket.articles.reverse_each do |local_article|
        next if local_article.created_at > current_time
        next if local_article.created_by_id != @item[:user_id]
        next if local_article.internal

        local_type = Ticket::Article::Type.lookup(id: local_article.type_id)
        return false if !local_type
        next if !local_type.communication

        local_sender = Ticket::Article::Sender.lookup(id: local_article.sender_id)
        return false if !local_sender

        Karma::ActivityLog.add('ticket close', user, 'Ticket', ticket.id)
        break
      end
    end

    # pending state
    if (!state_before.next_state_id && state_before.state_type.name != 'pending reminder') && (state_now.next_state_id || state_now.state_type.name == 'pending reminder')
      Karma::ActivityLog.add('ticket pending state', user, 'Ticket', ticket.id)
    end

    true
  end

  def ticket_article_karma(user)
    return if !@item[:article_id]

    article = Ticket::Article.lookup(id: @item[:article_id])
    return if !article

    # get sender
    sender = Ticket::Article::Sender.lookup(id: article.sender_id)
    return if !sender
    return if sender.name != 'Agent'

    # get type
    type = Ticket::Article::Type.lookup(id: article.type_id)
    return if !type
    return if !type.communication

    ### answer sent (check last action time / within what time?)
    articles = Ticket::Article.where(ticket_id: article.ticket_id).order(created_at: :asc, id: :asc)
    if articles.count > 1
      last_sender_customer = nil
      last_customer_contact = nil
      articles.each do |local_article|
        next if local_article.id == article.id
        next if local_article.internal

        local_type = Ticket::Article::Type.lookup(id: local_article.type_id)
        return false if !local_type
        next if !local_type.communication

        local_sender = Ticket::Article::Sender.lookup(id: local_article.sender_id)
        return false if !local_sender
        next if local_sender.name == 'System'

        last_sender_customer = local_sender.name == 'Customer'

        next if local_sender.name != 'Customer'

        last_customer_contact = local_article.created_at
      end
      if last_sender_customer && last_customer_contact
        diff =  article.created_at - last_customer_contact
        if diff >= 0
          if diff < 1.hour
            Karma::ActivityLog.add('ticket answer 1h', user, 'Ticket', @item[:object_id])
          elsif diff < 2.hours
            Karma::ActivityLog.add('ticket answer 2h', user, 'Ticket', @item[:object_id])
          elsif diff < 12.hours
            Karma::ActivityLog.add('ticket answer 12h', user, 'Ticket', @item[:object_id])
          elsif diff < 24.hours
            Karma::ActivityLog.add('ticket answer 24h', user, 'Ticket', @item[:object_id])
          end
        end
      end
    end

    ### text module
    if article.preferences[:text_module_ids].present?
      Karma::ActivityLog.add('text module', user, 'Ticket', @item[:object_id])
    end

    true
  end

  def tagging(user)
    return if @item[:type] != 'create'

    tag = Tag.lookup(id: @item[:object_id])
    return if !tag

    Karma::ActivityLog.add('tagging', user, tag.tag_object.name, tag.o_id)
  end

end

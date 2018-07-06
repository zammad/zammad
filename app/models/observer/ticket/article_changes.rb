# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::ArticleChanges < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)

    changed = false
    if article_count_update(record)
      changed = true
    end

    if first_response_at_update(record)
      changed = true
    end

    if sender_type_update(record)
      changed = true
    end

    if last_contact_update_at(record)
      changed = true
    end

    # save ticket
    if !changed
      record.ticket.touch # rubocop:disable Rails/SkipsModelValidations
      return
    end
    record.ticket.save!
  end

  def after_destroy(record)
    changed = false
    if article_count_update(record)
      changed = true
    end

    # save ticket
    if !changed
      record.ticket.touch # rubocop:disable Rails/SkipsModelValidations
      return
    end
    record.ticket.save!
  end

  # get article count
  def article_count_update(record)
    current_count = record.ticket.article_count
    sender = Ticket::Article::Sender.lookup(name: 'System')
    count = Ticket::Article.where(ticket_id: record.ticket_id).where('sender_id NOT IN (?)', sender.id).count
    return false if current_count == count
    record.ticket.article_count = count
    true
  end

  # set frist response
  def first_response_at_update(record)

    # return if we run import mode
    return false if Setting.get('import_mode')

    # if article in internal
    return false if record.internal

    # if sender is not agent
    sender = Ticket::Article::Sender.lookup(id: record.sender_id)
    return false if sender.name != 'Agent'

    # if article is a message to customer
    type = Ticket::Article::Type.lookup(id: record.type_id)
    return false if !type.communication

    # check if first_response_at is already set
    return false if record.ticket.first_response_at

    # set first_response_at
    record.ticket.first_response_at = record.created_at

    true
  end

  # set sender type
  def sender_type_update(record)

    # ignore if create channel is already set
    count = Ticket::Article.where(ticket_id: record.ticket_id).count
    return false if count > 1

    record.ticket.create_article_type_id   = record.type_id
    record.ticket.create_article_sender_id = record.sender_id
    true
  end

  # set last contact
  def last_contact_update_at(record)

    # if article in internal
    return false if record.internal

    # if sender is system
    sender = Ticket::Article::Sender.lookup(id: record.sender_id)
    return false if sender.name == 'System'

    # if article is a message to customer
    return false if !Ticket::Article::Type.lookup(id: record.type_id).communication

    # if sender is customer
    sender = Ticket::Article::Sender.lookup(id: record.sender_id)
    ticket = record.ticket
    if sender.name == 'Customer'

      # in case, update last_contact_customer_at on any customer follow up
      if Setting.get('ticket_last_contact_behaviour') == 'based_on_customer_reaction'

        # set last_contact_at customer
        record.ticket.last_contact_customer_at = record.created_at

        # set last_contact
        record.ticket.last_contact_at = record.created_at

        return true
      end

      # if customer is sending agains, ignore update of last contact (usecase of update escalation)
      return false if ticket.last_contact_customer_at &&
                      ticket.last_contact_at &&
                      ticket.last_contact_customer_at == ticket.last_contact_at

      # check if last communication is done by agent, else do not set last_contact_customer_at
      if ticket.last_contact_customer_at.nil? ||
         ticket.last_contact_agent_at.nil? ||
         ticket.last_contact_agent_at.to_i > ticket.last_contact_customer_at.to_i

        # set last_contact_at customer
        record.ticket.last_contact_customer_at = record.created_at

        # set last_contact
        record.ticket.last_contact_at = record.created_at
      end
      return true
    end

    # if sender is not agent
    return false if sender.name != 'Agent'

    # set last_contact_agent_at
    record.ticket.last_contact_agent_at = record.created_at

    # set last_contact
    record.ticket.last_contact_at = record.created_at

    true
  end
end

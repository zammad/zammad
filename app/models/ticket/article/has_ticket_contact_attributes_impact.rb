# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Ticket::Article::HasTicketContactAttributesImpact
  extend ActiveSupport::Concern

  included do
    after_create :update_ticket_article_attributes
    after_destroy :update_ticket_count_attribute
  end

  private

  def update_ticket_article_attributes

    changed = false
    if article_count_update
      changed = true
    end

    if first_response_at_update
      changed = true
    end

    if sender_type_update
      changed = true
    end

    if last_contact_update_at
      changed = true
    end

    # save ticket
    if !changed
      ticket.touch # rubocop:disable Rails/SkipsModelValidations
      return
    end
    ticket.save!
  end

  def update_ticket_count_attribute
    changed = false
    if article_count_update
      changed = true
    end

    # save ticket
    if !changed
      ticket.touch # rubocop:disable Rails/SkipsModelValidations
      return
    end
    ticket.save!
  end

  # get article count
  def article_count_update
    current_count = ticket.article_count
    sender = Ticket::Article::Sender.lookup(name: 'System')
    count = Ticket::Article.where(ticket_id: ticket_id).where.not(sender_id: sender.id).count
    return false if current_count == count

    ticket.article_count = count
    true
  end

  # set first response
  def first_response_at_update

    # return if we run import mode
    return false if Setting.get('import_mode')

    # if article in internal
    return false if internal

    # if sender is not agent
    sender = Ticket::Article::Sender.lookup(id: sender_id)
    return false if sender.name != 'Agent'

    # if article is a message to customer
    type = Ticket::Article::Type.lookup(id: type_id)
    return false if !type.communication

    # check if first_response_at is already set
    return false if ticket.first_response_at

    # set first_response_at
    ticket.first_response_at = created_at

    true
  end

  # set sender type
  def sender_type_update

    # ignore if create channel is already set
    count = Ticket::Article.where(ticket_id: ticket_id).count
    return false if count > 1

    ticket.create_article_type_id   = type_id
    ticket.create_article_sender_id = sender_id
    true
  end

  # set last contact
  def last_contact_update_at

    # if article in internal
    return false if internal

    # if sender is system
    sender = Ticket::Article::Sender.lookup(id: sender_id)
    return false if sender.name == 'System'

    # if article is a message to customer
    return false if !Ticket::Article::Type.lookup(id: type_id).communication

    # if sender is customer
    sender = Ticket::Article::Sender.lookup(id: sender_id)
    ticket = self.ticket
    if sender.name == 'Customer'

      # in case, update last_contact_customer_at on any customer follow-up
      if Setting.get('ticket_last_contact_behaviour') == 'based_on_customer_reaction'

        # set last_contact_at customer
        self.ticket.last_contact_customer_at = created_at

        # set last_contact
        self.ticket.last_contact_at = created_at

        return true
      end

      # if customer is sending again, ignore update of last contact (use case of update escalation)
      return false if ticket.last_contact_customer_at &&
                      ticket.last_contact_at &&
                      ticket.last_contact_customer_at == ticket.last_contact_at

      # check if last communication is done by agent, else do not set last_contact_customer_at
      if ticket.last_contact_customer_at.nil? ||
         ticket.last_contact_agent_at.nil? ||
         ticket.last_contact_agent_at.to_i > ticket.last_contact_customer_at.to_i

        # set last_contact_at customer
        self.ticket.last_contact_customer_at = created_at

        # set last_contact
        self.ticket.last_contact_at = created_at
      end
      return true
    end

    # if sender is not agent
    return false if sender.name != 'Agent'

    # set last_contact_agent_at
    self.ticket.last_contact_agent_at = created_at

    # set last_contact
    self.ticket.last_contact_at = created_at

    true
  end

end

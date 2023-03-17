# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Ticket::ArticlePolicy < ApplicationPolicy

  def show?
    access?(__method__)
  end

  def create?
    access?(__method__)
  end

  def update?
    ticket_policy.agent_update_access?
  end

  def destroy?
    return false if !access?('show?')

    # agents can destroy articles of type 'note'
    # which were created by themselves within the last x minutes

    if !user.permissions?('ticket.agent')
      return not_authorized('agent permission required')
    end

    if record.created_by_id != user.id
      return not_authorized('you can only delete your own notes')
    end

    if record.type.communication? && !record.internal?
      return not_authorized('communication articles cannot be deleted')
    end

    if deletable_timeframe? && record.created_at <= deletable_timeframe.ago
      return not_authorized('note is too old to be deleted')
    end

    true
  end

  private

  def deletable_timeframe_setting
    Setting.get('ui_ticket_zoom_article_delete_timeframe')
  end

  def deletable_timeframe?
    deletable_timeframe_setting&.positive?
  end

  def deletable_timeframe
    deletable_timeframe_setting.seconds
  end

  def access?(query)
    return false if record.internal && !ticket_policy.agent_read_access?

    ticket_policy.send(query)
  end

  def ticket_policy
    @ticket_policy ||= TicketPolicy.new(user, Ticket.lookup(id: record.ticket_id))
  end
end

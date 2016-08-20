# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Transaction::Trigger

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

    return if @item[:object] != 'Ticket'

    triggers = Trigger.where(active: true)
    return if triggers.empty?

    ticket = Ticket.lookup(id: @item[:object_id])
    return if !ticket
    if @item[:article_id]
      article = Ticket::Article.lookup(id: @item[:article_id])
    end

    original_user_id = UserInfo.current_user_id
    UserInfo.current_user_id = 1

    triggers.each { |trigger|
      condition = trigger.condition

      # check action
      if condition['ticket.action']
        next if condition['ticket.action']['operator'] == 'is' && condition['ticket.action']['value'] != @item[:type]
        next if condition['ticket.action']['operator'] != 'is' && condition['ticket.action']['value'] == @item[:type]
        condition.delete('ticket.action')
      end

      # check "has changed" options
      has_changed_condition_exists = false
      has_changed = false
      condition.each do |key, value|
        next if !value
        next if !value['operator']
        next if !value['operator']['has changed']
        has_changed_condition_exists = true

        # next if has changed? && !@item[:changes][attribute]
        (object_name, attribute) = key.split('.', 2)

        # remove condition item, because it has changed
        if @item[:changes][attribute]
          has_changed = true
          condition.delete(key)
          next
        end
        break
      end

      next if has_changed_condition_exists && !has_changed

      # check if selector is matching
      condition['ticket.id'] = {
        operator: 'is',
        value: ticket.id,
      }
      if article
        condition['article.id'] = {
          operator: 'is',
          value: article.id,
        }
      end

      ticket_count, tickets = Ticket.selectors(condition, 1)
      next if ticket_count.zero?
      next if tickets.first.id != ticket.id

      # check if min one article attribute is used
      article_selector = false
      trigger.condition.each do |key, _value|
        (object_name, attribute) = key.split('.', 2)
        next if object_name != 'article'
        next if attribute == 'id'
        article_selector = true
      end

      # check in min one attribute has changed
      if @item[:type] == 'update' && !article_selector
        match = false
        if has_changed_condition_exists && has_changed
          match = true
        else
          trigger.condition.each do |key, _value|
            (object_name, attribute) = key.split('.', 2)
            next if object_name != 'ticket'
            next if !@item[:changes][attribute]
            match = true
            break
          end
        end
        next if !match
      end

      ticket.perform_changes(trigger.perform, 'trigger', @item)
    }
    UserInfo.current_user_id = original_user_id
  end

end

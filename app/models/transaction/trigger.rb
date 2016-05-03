# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Transaction::Trigger

=begin
  {
    object: 'Ticket',
    type: 'update',
    object_id: 123,
    via_web: true,
    changes: {
      'attribute1' => [before, now],
      'attribute2' => [before, now],
    }
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

    UserInfo.current_user_id = 1

    triggers.each {|trigger|
      condition = trigger.condition

      # check action
      if condition['ticket.action']
        next if condition['ticket.action']['operator'] == 'is' && condition['ticket.action']['value'] != @item[:type]
        next if condition['ticket.action']['operator'] != 'is' && condition['ticket.action']['value'] == @item[:type]
        condition.delete('ticket.action')
      end

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
      next if ticket_count == 0
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
        trigger.condition.each do |key, _value|
          (object_name, attribute) = key.split('.', 2)
          next if object_name != 'ticket'
          next if !@item[:changes][attribute]
          match = true
          break
        end
        next if !match
      end

      ticket.perform_changes(trigger.perform, 'trigger', @item)
    }
  end

end

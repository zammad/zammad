# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

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

    triggers = if Rails.configuration.db_case_sensitive
                 Trigger.where(active: true).order('LOWER(name)')
               else
                 Trigger.where(active: true).order(:name)
               end
    return if triggers.empty?

    ticket = Ticket.lookup(id: @item[:object_id])
    return if !ticket
    if @item[:article_id]
      article = Ticket::Article.lookup(id: @item[:article_id])
    end

    original_user_id = UserInfo.current_user_id

    Transaction.execute(reset_user_id: true, disable: ['Transaction::Trigger', 'Transaction::Notification']) do
      triggers.each { |trigger|
        condition = trigger.condition

        # check if one article attribute is used
        one_has_changed_done = false
        article_selector = false
        trigger.condition.each do |key, _value|
          (object_name, attribute) = key.split('.', 2)
          next if object_name != 'article'
          next if attribute == 'id'
          article_selector = true
        end
        if article && article_selector
          one_has_changed_done = true
        end
        if article && @item[:type] == 'update'
          one_has_changed_done = true
        end

        # check ticket "has changed" options
        has_changed_done = true
        condition.each do |key, value|
          next if !value
          next if !value['operator']
          next if !value['operator']['has changed']

          # remove condition item, because it has changed
          (object_name, attribute) = key.split('.', 2)
          next if object_name != 'ticket'
          next if !@item[:changes]
          next if !@item[:changes].key?(attribute)
          condition.delete(key)
          one_has_changed_done = true
        end

        # check if we have not matching "has changed" attributes
        condition.each do |_key, value|
          next if !value
          next if !value['operator']
          next if !value['operator']['has changed']
          has_changed_done = false
          break
        end

        # check ticket action
        if condition['ticket.action']
          next if condition['ticket.action']['operator'] == 'is' && condition['ticket.action']['value'] != @item[:type]
          next if condition['ticket.action']['operator'] != 'is' && condition['ticket.action']['value'] == @item[:type]
          condition.delete('ticket.action')
        end
        next if !has_changed_done

        # check in min one attribute of condition has changed on update
        one_has_changed_condition = false
        if @item[:type] == 'update'

          # verify if ticket condition exists
          condition.each do |key, _value|
            (object_name, attribute) = key.split('.', 2)
            next if object_name != 'ticket'
            one_has_changed_condition = true
            next if !@item[:changes] || !@item[:changes].key?(attribute)
            one_has_changed_done = true
            break
          end
          next if one_has_changed_condition && !one_has_changed_done
        end

        # check if ticket selector is matching
        condition['ticket.id'] = {
          operator: 'is',
          value: ticket.id,
        }
        next if article_selector && !article

        # check if article selector is matching
        if article_selector
          condition['article.id'] = {
            operator: 'is',
            value: article.id,
          }
        end

        # verify is condition is matching
        ticket_count, tickets = Ticket.selectors(condition, 1)
        next if ticket_count.blank?
        next if ticket_count.zero?
        next if tickets.first.id != ticket.id
        user_id = ticket.updated_by_id
        if article
          user_id = article.updated_by_id
        end
        ticket.perform_changes(trigger.perform, 'trigger', @item, user_id)
      }
    end
    UserInfo.current_user_id = original_user_id
  end

end

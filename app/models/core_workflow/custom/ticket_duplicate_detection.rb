# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Custom::TicketDuplicateDetection < CoreWorkflow::Custom::Backend
  def saved_attribute_match?
    @saved_attribute_match ||= ticket_create? && enabled? && run_once? && any_attribute_match?
  end

  def selected_attribute_match?
    saved_attribute_match?
  end

  def ticket_create?
    object?(Ticket) && screen?('create_middle')
  end

  def enabled?
    Setting.get('ticket_duplicate_detection') && available_for_user? && detect_attributes.present?
  end

  def available_for_user?
    Setting.get('ticket_duplicate_detection_role_ids').any? do |role_id|
      current_user.role_ids.include? role_id.to_i
    end
  end

  def run_once?
    @result_object.result[:fill_in]['ticket_duplicate_detection'].blank?
  end

  def detect_attributes
    @detect_attributes ||= Setting.get('ticket_duplicate_detection_attributes')
  end

  def any_attribute_match?
    return true if @condition_object.payload['last_changed_attribute'].blank?

    detect_attributes.include?(@condition_object.payload['last_changed_attribute'])
  end

  def params_set?
    detect_attributes.all? { |key| params[key].present? }
  end

  def search_selector
    @search_selector ||= begin
      where_condition_selector = {}
      detect_attributes.each do |key|
        where_condition_selector["ticket.#{key}"] = {
          operator: 'is',
          value:    params[key],
        }
      end

      if Setting.get('ticket_duplicate_detection_search') == 'open'
        where_condition_selector['ticket.state_id'] = {
          operator: 'is',
          value:    Ticket::State.by_category_ids(:open).map(&:to_s),
        }
      end

      where_condition_selector
    end
  end

  def permission_system?
    @permission_system ||= Setting.get('ticket_duplicate_detection_permission_level') == 'system'
  end

  def show_tickets?
    @show_tickets ||= Setting.get('ticket_duplicate_detection_show_tickets') == true
  end

  def ticket_limit
    10
  end

  def search_tickets
    return Ticket.selectors(search_selector, limit: ticket_limit, execution_time: true, order_by: :id) if permission_system?

    Ticket.selectors(search_selector, current_user: current_user, limit: ticket_limit, execution_time: true, order_by: :id)
  end

  def show_value
    if !params_set?
      return {
        count: 0,
        items: [],
      }
    end

    count, tickets = search_tickets

    items = []
    if show_tickets? && tickets.present?
      items = tickets.select do |ticket|
                TicketPolicy.new(current_user, ticket).show?
              end.map do |ticket|
        [
          ticket.id,
          ticket.number,
          ticket.title,
        ]
      end
    end

    {
      count: count || 0,
      items: items,
    }
  end

  def perform
    result('show', 'ticket_duplicate_detection')
    result('fill_in', 'ticket_duplicate_detection', show_value, skip_rerun: true)
  end
end

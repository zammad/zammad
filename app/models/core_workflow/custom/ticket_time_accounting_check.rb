# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Custom::TicketTimeAccountingCheck < CoreWorkflow::Custom::Backend
  def saved_attribute_match?
    @saved_attribute_match ||= !@result_object.form_updater && ticket_edit? && enabled?
  end

  def selected_attribute_match?
    saved_attribute_match?
  end

  def ticket_edit?
    object?(Ticket) && screen?('edit')
  end

  def enabled?
    Setting.get('time_accounting') && available_for_user?
  end

  def available_for_user?
    saved.persisted? && TicketPolicy.new(current_user, saved).agent_update_access?
  end

  def selector
    @selector ||= Setting.get('time_accounting_selector')&.dig('condition') || {}
  end

  def any_attribute_match?
    @condition_object.condition_selector_match?(selector)
  end

  def perform
    change_flags({ time_accounting: any_attribute_match? })
  end
end

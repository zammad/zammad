# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Custom::SecondaryOrganization < CoreWorkflow::Custom::Backend
  def saved_attribute_match?
    object?(Ticket)
  end

  def selected_attribute_match?
    object?(Ticket)
  end

  def perform
    return organization_off if user.blank?
    return organization_on if user.organizations.present?

    organization_off
  end

  def user
    @user ||= begin
      if params['customer_id'].present? && @result_object.user.permissions?('ticket.agent')
        User.find_by(id: params['customer_id'])
      elsif !@result_object.user.permissions?('ticket.agent') && @result_object.user.permissions?('ticket.customer')
        @result_object.user
      end
    end
  end

  def organization_off
    result('hide', 'organization_id')
    result('set_optional', 'organization_id')
  end

  def organization_on
    result('show', 'organization_id')
    result('set_mandatory', 'organization_id')
  end
end

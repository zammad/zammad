# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CoreWorkflow::Custom::AdminSla < CoreWorkflow::Custom::Backend
  def saved_attribute_match?
    object?(Sla)
  end

  def selected_attribute_match?
    object?(Sla)
  end

  def first_response_time_enabled
    return 'set_mandatory' if params['first_response_time_enabled'].present?

    'set_optional'
  end

  def update_time_enabled
    return 'set_mandatory' if params['update_time_enabled'].present?

    'set_optional'
  end

  def solution_time_enabled
    return 'set_mandatory' if params['solution_time_enabled'].present?

    'set_optional'
  end

  def perform

    # make fields mandatory if checkbox is checked
    result(first_response_time_enabled, 'first_response_time_in_text')
    result(update_time_enabled, 'update_time_in_text')
    result(solution_time_enabled, 'solution_time_in_text')
  end
end

# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ChecksConditionValidation
  extend ActiveSupport::Concern

  included do
    before_create :validate_condition
    before_update :validate_condition
  end

  def validate_condition
    # use Marshal to do a deep copy of the condition hash
    validate_condition = Marshal.load(Marshal.dump(condition))

    # check if a valid condition got inserted.
    validate_condition.delete('ticket.action')
    validate_condition.delete('execution_time.calendar_id')
    validate_condition.each do |key, value|
      next if !value
      next if !value['operator']
      next if !value['operator']['has changed']

      validate_condition.delete(key)
    end

    validate_condition['ticket.id'] = {
      operator: 'is',
      value:    1,
    }

    ticket_count, _tickets = Ticket.selectors(validate_condition, limit: 1, current_user: User.find(1))
    return true if ticket_count.present?

    raise Exceptions::UnprocessableEntity, 'Invalid ticket selector conditions'
  end
end

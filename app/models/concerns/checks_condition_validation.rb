# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module ChecksConditionValidation
  extend ActiveSupport::Concern

  included do
    before_create :validate_condition
    before_update :validate_condition
  end

  def validate_condition
    raise Exceptions::UnprocessableEntity, __('Invalid ticket selector conditions') if !Ticket::Selector::Sql.new(selector: condition, options: { current_user: User.find(1) }).valid?
  end
end

# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Mention::Validation < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    check_user_permission
  end

  private

  def check_user_permission
    return if MentionPolicy.new(record.user, record).create?

    invalid_because(:user, 'has no ticket.agent permissions')
  end

  def invalid_because(attribute, message)
    record.errors.add attribute, message
  end
end

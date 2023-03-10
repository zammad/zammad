# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Validations::MentionValidator < ActiveModel::Validator
  def validate(record)
    return if Mention.mentionable? record.mentionable, record.user

    record.errors.add :user, __('has no agent access to this ticket')
  end
end

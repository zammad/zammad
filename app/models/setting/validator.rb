# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Setting::Validator < ActiveModel::Validator
  def validate(record)
    return if record.preferences.blank? || record.preferences[:validations].blank?

    failed_validation = record.preferences[:validations]
      .lazy
      .map { |klass| klass.constantize.new(record).run }
      .find { |elem| !elem[:success] }

    return if !failed_validation

    record.errors.add(:base, :invalid, message: failed_validation[:message])
  end
end

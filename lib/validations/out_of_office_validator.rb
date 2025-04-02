# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Validations::OutOfOfficeValidator < ActiveModel::Validator
  def validate(record)
    validate_replacement_user(record, required: record.out_of_office)
    validate_dates(record, required: record.out_of_office)
  end

  private

  def validate_dates(record, required:)
    if record.out_of_office_start_at.blank?
      if required
        record.errors.add(:out_of_office_start_at, :blank)
      end

      return
    end

    if record.out_of_office_end_at.blank?
      if required
        record.errors.add :out_of_office_end_at, :blank
      end

      return
    end

    return if record.out_of_office_start_at <= record.out_of_office_end_at

    record.errors.add :base, :less_than_or_equal_to,
                      message: __('Out of Office start date has to be earlier than or equal to end date')
  end

  def validate_replacement_user(record, required:)
    if !record.out_of_office_replacement_id
      if required
        record.errors.add :out_of_office_replacement_id, :blank
      end

      return
    end

    return if User.exists? record.out_of_office_replacement_id

    record.errors.add :out_of_office_replacement_id, :invalid
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Validations::DateRangeValidator < ActiveModel::Validator

  # Elasticsearch and RFC 3339 only support dates with a four digit year (#6306)
  YEAR_RANGE = (1..9999)

  def validate(record)
    record.class.columns_hash.each do |name, column|
      next if %i[date datetime].exclude?(column.type)
      next if !record.will_save_change_to_attribute?(name)

      value = record[name]
      next if value.blank?
      next if YEAR_RANGE.cover?(value.year)

      record.errors.add(name.to_sym, __('must have a year between 1 and 9999'))
    end
  end
end

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Setting::Transformation::Base
  attr_reader :record

  def initialize(record)
    @record = record
  end

  def value
    record.state_current['value']
  end

  def update_value(input)
    record.state_current['value'] = input
  end
end

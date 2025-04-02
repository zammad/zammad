# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Setting::Validation::Base
  attr_reader :record, :value

  def initialize(record)
    @record = record
    @value  = record.state_current.fetch('value', {})
  end

  private

  def result_success
    { success: true }
  end

  def result_failed(msg)
    { success: false, message: msg }
  end
end

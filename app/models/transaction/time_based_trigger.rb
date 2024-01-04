# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Transaction::TimeBasedTrigger < Transaction::Trigger
  def perform
    return if !time_based_trigger?

    super
  end

  private

  def trigger_activator
    :time
  end

  def time_based_trigger?
    %w[reminder_reached escalation escalation_warning].include? @item[:type]
  end
end

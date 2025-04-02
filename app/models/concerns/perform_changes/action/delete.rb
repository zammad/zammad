# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class PerformChanges::Action::Delete < PerformChanges::Action
  def self.phase
    :initial
  end

  def execute(prepared_actions)
    Rails.logger.info { "Deleted ticket from #{origin} #{performable.perform.inspect} #{record.class.name}.find(#{id})" }

    record.destroy!

    prepared_actions.delete(:before_save)
  end
end

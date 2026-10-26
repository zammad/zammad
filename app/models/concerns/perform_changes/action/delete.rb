# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class PerformChanges::Action::Delete < PerformChanges::Action
  def self.phase
    :initial
  end

  def execute(prepared_actions)
    Rails.logger.info { "Deleted ticket from #{origin} #{performable.perform.inspect} #{record.class.name}.find(#{id})" }

    record.destroy!

    # Nothing is left to act on, so remaining phases (e.g. notifications or articles) are skipped (#6463).
    prepared_actions.delete(:before_save)
    prepared_actions.delete(:after_save)
    prepared_actions.delete(:after_commit)
  end
end

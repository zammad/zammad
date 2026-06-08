# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module TouchesPerformReferences
  extend ActiveSupport::Concern

  included do
    after_save :touch_perform_references_on_save
    after_destroy :touch_perform_references_on_destroy
  end

  private

  def touch_perform_references_on_destroy
    AI::Agent.all_from_performable(self).each(&:touch)
  end

  def touch_perform_references_on_save
    agent_ids         = AI::Agent.from_performable_ids(self)
    agent_ids_was     = AI::Agent.from_performable_ids(perform_previously_was)
    agent_ids_changed = agent_ids.sort != agent_ids_was.sort

    return if !agent_ids_changed && !name_previously_changed?

    AI::Agent.where(id: agent_ids | agent_ids_was).each(&:touch)
  end
end

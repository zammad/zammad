# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module TouchesPerformReferences
  extend ActiveSupport::Concern

  included do
    after_save :touch_perform_references_on_save
    after_destroy :touch_perform_references_on_destroy
  end

  private

  def touch_perform_references_on_destroy
    AI::Agent.from_performable(self)&.touch # rubocop:disable Rails/SkipsModelValidations
  end

  def touch_perform_references_on_save
    agent_id         = AI::Agent.from_performable_id(self)
    agent_id_was     = AI::Agent.from_performable_id(perform_previously_was)
    agent_id_changed = (agent_id.present? || agent_id_was.present?) && (agent_id != agent_id_was)

    return if !agent_id_changed && !name_previously_changed?

    AI::Agent.where(id: [agent_id, agent_id_was]).each(&:touch)
  end
end

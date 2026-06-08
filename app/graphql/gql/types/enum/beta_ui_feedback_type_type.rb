# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class BetaUiFeedbackTypeType < BaseEnum
    description 'BETA UI feedback type'

    value 'manual_feedback', 'Manual feedback'
    value 'milestone_question', 'Milestone question'
    value 'back_to_old_ui', 'Switch back to old UI'
  end
end

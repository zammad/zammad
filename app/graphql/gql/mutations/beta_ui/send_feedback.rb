# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class BetaUi::SendFeedback < BaseMutation
    description 'Submits user feedback on the new BETA UI'

    argument :input, Gql::Types::Input::BetaUi::FeedbackInputType, required: true, description: 'Input for the feedback on BETA UI'

    field :success, Boolean, null: false, description: 'Was the submission successful?'

    requires_enabled_setting 'ui_desktop_beta_switch'

    def resolve(input:)
      {
        success: Service::BetaUi::SendFeedback.new(**input).execute,
      }
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::BetaUi
  class FeedbackInputType < Gql::Types::BaseInputObject
    description 'Input for the feedback on BETA UI.'

    argument :type, Gql::Types::Enum::BetaUiFeedbackTypeType, description: 'The type of feedback'
    argument :comment, String, description: 'The feedback comment text'
    argument :time_spent, Integer, description: 'Time spent in the BETA UI in minutes'
    argument :rating, Integer, required: false, validates: { numericality: { within: 1..5 } }, description: 'The feedback rating (1-5)'

  end
end

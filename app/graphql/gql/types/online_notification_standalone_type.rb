# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class OnlineNotificationStandaloneType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields # Instead of IsModelObject to have custom #created_by and #updated_by
    include Gql::Types::Concerns::HasInternalIdField

    description 'Standalone notification for a user, not related to a specific database object'

    field :data, Gql::Types::OnlineNotificationStandalone::DataUnionType, null: false

    def data
      case object.kind
      when 'bulk_job'
        ::OnlineNotificationStandalone::BulkJobData.new(**object.data.symbolize_keys)
      when 'kb_answer_generation_failed'
        ::OnlineNotificationStandalone::KbAnswerGenerationFailedData.new(**object.data.symbolize_keys)
      end
    end
  end
end

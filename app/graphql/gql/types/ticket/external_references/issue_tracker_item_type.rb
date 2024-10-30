# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket::ExternalReferences
  class IssueTrackerItemType < Gql::Types::BaseObject
    description 'Issue tracker item for an external reference for a ticket'

    field :issue_id, Integer,
          method: :id, null: false, description: 'The issue ID from the external issue tracker'
    field :title, String, null: false, description: 'The title of the issue'
    field :url, Gql::Types::UriHttpStringType, null: false, description: 'The URL of the issue'
    field :state, Gql::Types::Enum::Ticket::ExternalReferences::IssueTrackerItemStateType,
          method: :icon_state, null: false, description: 'The state of the issue'

    field :assignees, [String, { null: false }], description: 'The assignees of the issue'
    field :milestone, String, description: 'The milestone of the issue'
    field :labels,
          [Gql::Types::Ticket::ExternalReferences::IssueTrackerItem::LabelType, { null: false }],
          description: 'The labels of the issue'
  end
end

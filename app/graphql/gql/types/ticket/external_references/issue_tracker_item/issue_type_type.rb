# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket::ExternalReferences::IssueTrackerItem
  class IssueTypeType < Gql::Types::BaseObject
    description 'The issue type of the Issue tracker item'

    field :name,  String, null: false, description: 'The name of the issue type'
    field :color, String, description: 'The GitHub color identifier of the issue type (e.g. PURPLE, RED)'
  end
end

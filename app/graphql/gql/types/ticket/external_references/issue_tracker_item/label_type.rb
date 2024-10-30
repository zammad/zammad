# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket::ExternalReferences::IssueTrackerItem
  class LabelType < Gql::Types::BaseObject
    description 'The labels of the Issue tracker item'

    field :title, String, null: false, description: 'The title of the label'
    field :color, String, null: false, description: 'The color of the label'
    field :text_color, String, null: false, description: 'The text color of the label'
  end
end

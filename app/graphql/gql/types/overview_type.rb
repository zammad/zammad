# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class OverviewType < Gql::Types::BaseObject
    include Gql::Concern::IsModelObject

    def self.authorize(_object, ctx)
      ctx.current_user
    end

    description 'Ticket overviews'

    field :name, String, null: false
    field :link, String, null: false
    field :prio, Integer, null: false
    # field :condition, String, null: false
    field :order, String, null: false
    # field :group_by, String, null: true
    # field :group_direction, String, null: true
    # field :organization_shared, Boolean, null: false
    # field :out_of_office, Boolean, null: false
    field :view, String, null: false
    field :active, Boolean, null: false

    field :ticket_count, Integer, null: false, description: 'Count of tickets the authenticated user may see in this overview'

    def ticket_count
      ::Ticket::Overviews.tickets_for_overview(object, context.current_user).count
    end
  end
end

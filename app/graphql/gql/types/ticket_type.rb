# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class TicketType < BaseObject
    include Gql::Concern::IsModelObject

    def self.authorize(object, ctx)
      Pundit.authorize ctx.current_user, object, :show?
    end

    description 'Tickets'

    # def self.scope_items(items, ctx)
    #   items.where(title: '123')
    # end

    # field :group_id, Integer, null: false
    # field :priority_id, Integer, null: false
    # field :state_id, Integer, null: false

    field :organization, Gql::Types::OrganizationType, null: true
    field :number, String, null: false
    field :title, String, null: false
    field :owner, Gql::Types::UserType, null: false
    field :customer, Gql::Types::UserType, null: false
    field :note, String, null: true

    field :first_response_at, GraphQL::Types::ISO8601DateTime, null: true
    field :first_response_escalation_at, GraphQL::Types::ISO8601DateTime, null: true
    field :first_response_in_min, Integer, null: true
    field :first_response_diff_in_min, Integer, null: true
    field :close_at, GraphQL::Types::ISO8601DateTime, null: true
    field :close_escalation_at, GraphQL::Types::ISO8601DateTime, null: true
    field :close_in_min, Integer, null: true
    field :close_diff_in_min, Integer, null: true
    field :update_escalation_at, GraphQL::Types::ISO8601DateTime, null: true
    field :update_in_min, Integer, null: true
    field :update_diff_in_min, Integer, null: true
    field :last_contact_at, GraphQL::Types::ISO8601DateTime, null: true
    field :last_contact_agent_at, GraphQL::Types::ISO8601DateTime, null: true
    field :last_contact_customer_at, GraphQL::Types::ISO8601DateTime, null: true
    field :last_owner_update_at, GraphQL::Types::ISO8601DateTime, null: true
    field :escalation_at, GraphQL::Types::ISO8601DateTime, null: true
    field :pending_time, GraphQL::Types::ISO8601DateTime, null: true

    # field :create_article_type_id, Integer, null: true
    # field :create_article_sender_id, Integer, null: true
    field :article_count, Integer, null: true
    # field :type, String, null: true
    field :time_unit, Float, null: true
    field :preferences, GraphQL::Types::JSON, null: true
  end
end

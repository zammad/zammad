# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class BaseInputType < Gql::Types::BaseInputObject
    include Gql::Types::Input::Concerns::ProvidesObjectAttributeValues

    argument :owner_id, GraphQL::Types::ID, required: false, description: 'The owner of the ticket.', loads: Gql::Types::UserType
    argument :customer, Gql::Types::Input::Ticket::CustomerInputType, required: false, description: 'The customer of the ticket.'
    argument :organization_id, GraphQL::Types::ID, required: false, description: 'The organization of the ticket.', loads: Gql::Types::OrganizationType
    argument :priority_id, GraphQL::Types::ID, required: false, description: 'The priority of the ticket.', loads: Gql::Types::Ticket::PriorityType
    argument :state_id, GraphQL::Types::ID, required: false, description: 'The state of the ticket.', loads: Gql::Types::Ticket::StateType
    argument :pending_time, GraphQL::Types::ISO8601DateTime, required: false, description: 'The pending time of the ticket.'

    argument :article, Gql::Types::Input::Ticket::ArticleInputType, required: false, description: 'The article data.'

    def self.agent_only_fields
      %w[owner_id customer priority_id pending_time]
    end

    def self.agent_only_fields_access
      :change
    end

    def self.sanitize_agent_only_fields!(value, user:, group_id:)
      return if user.group_access?(group_id, agent_only_fields_access)

      value.delete_if { |k, _v| agent_only_fields.include?(k.to_s) || agent_only_fields.include?("#{k}_id") }
    end
  end
end

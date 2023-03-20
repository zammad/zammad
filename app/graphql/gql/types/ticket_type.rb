# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class TicketType < BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalIdField
    include Gql::Types::Concerns::HasInternalNoteField
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Tickets'

    # Even though we might fetch tickets with 'overview' permissions in the first place,
    #   check that they always have 'read' permissions as well, as that is logicaly
    #   included in 'overview'.
    def self.scope_items(items, ctx)
      TicketPolicy::ReadScope.new(ctx.current_user, items).resolve
    end

    implements Gql::Types::ObjectAttributeValuesInterface
    implements Gql::Types::TagsInterface

    belongs_to :group, Gql::Types::GroupType, null: false
    belongs_to :priority, Gql::Types::Ticket::PriorityType, null: false
    belongs_to :state, Gql::Types::Ticket::StateType, null: false
    belongs_to :organization, Gql::Types::OrganizationType
    belongs_to :owner, Gql::Types::UserType, null: false
    belongs_to :customer, Gql::Types::UserType, null: false
    belongs_to :create_article_type, Gql::Types::Ticket::Article::TypeType

    # Don't expose articles at this point as they can only be used safely with agent read permission.
    # field :articles, Gql::Types::Ticket::ArticleType.connection_type, null: false

    field :policy, Gql::Types::Policy::TicketType, null: false, method: :itself

    field :number, String, null: false
    field :title, String, null: false

    field :first_response_at, GraphQL::Types::ISO8601DateTime
    field :first_response_escalation_at, GraphQL::Types::ISO8601DateTime
    field :first_response_in_min, Integer
    field :first_response_diff_in_min, Integer
    field :close_at, GraphQL::Types::ISO8601DateTime
    field :close_escalation_at, GraphQL::Types::ISO8601DateTime
    field :close_in_min, Integer
    field :close_diff_in_min, Integer
    field :update_escalation_at, GraphQL::Types::ISO8601DateTime
    field :update_in_min, Integer
    field :update_diff_in_min, Integer
    field :last_contact_at, GraphQL::Types::ISO8601DateTime
    field :last_contact_agent_at, GraphQL::Types::ISO8601DateTime
    field :last_contact_customer_at, GraphQL::Types::ISO8601DateTime
    field :last_owner_update_at, GraphQL::Types::ISO8601DateTime
    field :escalation_at, GraphQL::Types::ISO8601DateTime
    field :pending_time, GraphQL::Types::ISO8601DateTime

    # field :create_article_sender_id, Integer
    # field :article_count, Integer, description: "Count of ticket articles that were not sent by 'System'."
    # field :type, String
    field :time_unit, Float
    field :preferences, GraphQL::Types::JSON

    field :state_color_code, Gql::Types::Enum::TicketStateColorCodeType, null: false, description: 'Ticket color indicator state.'

    internal_fields do
      field :subscribed, Boolean, null: true
      field :mentions, Gql::Types::MentionType.connection_type, null: true
    end

    def subscribed
      ::Mention.subscribed?(@object, context.current_user)
    end

    def state_color_code
      if %w[new open].include?(state_type_name)
        return ticket_is_escalating? ? 'escalating' : 'open'
      elsif state_type_name == 'pending reminder'
        return ticket_is_over_pending_time? ? 'open' : 'pending'
      elsif state_type_name == 'pending action'
        return 'pending'
      end

      'closed'
    end

    private

    def ticket_is_escalating?
      @object.escalation_at && @object.escalation_at < Time.zone.now
    end

    def ticket_is_over_pending_time?
      @object.pending_time && @object.pending_time < Time.zone.now
    end

    def state_type_name
      @state_type_name ||= @object.state.state_type.name
    end
  end
end

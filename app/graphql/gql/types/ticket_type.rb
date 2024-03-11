# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class TicketType < BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasScopedModelUserRelations
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
    field :initial_channel, Gql::Types::Enum::Channel::AreaType, description: 'The initial channel of the ticket.'

    # field :create_article_sender_id, Integer
    # field :article_count, Integer, description: "Count of ticket articles that were not sent by 'System'."
    # field :type, String
    field :preferences, GraphQL::Types::JSON

    field :state_color_code, Gql::Types::Enum::TicketStateColorCodeType, null: false, description: 'Ticket color indicator state.'

    scoped_fields do
      field :time_unit, Float
      field :time_units_per_type, [Gql::Types::Ticket::TimeAccountingTypeSumType]
    end

    internal_fields do
      field :subscribed, Boolean, null: true
      field :mentions, Gql::Types::MentionType.connection_type, null: true
    end

    def initial_channel
      return nil if !@object.preferences['channel_area']

      @object.preferences['channel_area']
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

    def time_units_per_type
      time_units_per_type = time_units_per_type_data
      return [] if time_units_per_type.empty?

      if time_units_per_type.length.eql?(1) && time_units_per_type[0][:name].eql?(__('None'))
        []
      else
        time_units_per_type
      end
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

    def time_units_per_type_data
      return [] if !@object.ticket_time_accounting.exists?(['type_id IS NOT NULL'])

      @object.ticket_time_accounting
        .group_by { |r| r[:type_id] }
        .map { |type_id, entries| time_accounting_type_sum(type_id, entries) }
        .flatten
        .sort_by { |r| r[:time_unit] }
        .reverse
    end

    def time_accounting_type_sum(type_id, entries)
      [
        name:      time_accounting_types[type_id] || __('None'),
        time_unit: entries.inject(0) { |sum, entry| sum + entry.time_unit },
      ]
    end

    def time_accounting_types
      @time_accounting_types ||= ::Ticket::TimeAccounting::Type.all.to_h { |type| [type.id, type.name] }
    end
  end
end

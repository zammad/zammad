# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class OverviewType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalIdField
    include Gql::Types::Concerns::HasPunditAuthorization
    include Gql::Concerns::HandlesOverviewCaching

    description 'Ticket overviews'

    field :name, String, null: false
    field :link, String, null: false
    field :prio, Integer, null: false
    # field :condition, String, null: false
    # field :order, String, null: false
    field :order_by, String, null: false
    field :order_direction, Gql::Types::Enum::OrderDirectionType, null: false
    field :group_by, String
    field :group_direction, Gql::Types::Enum::OrderDirectionType
    field :organization_shared, Boolean, null: true
    field :out_of_office, Boolean, null: true
    # field :view, String, null: false
    field :active, Boolean, null: false

    field :view_columns_raw, [String, { null: false }], null: false, description: 'Columns to be shown on screen, mapped to actual internal field IDs'
    field :view_columns, [Gql::Types::KeyValueType, { null: false }], null: false, description: 'Columns to be shown on screen, with assigned label values'
    field :order_columns, [Gql::Types::KeyValueType, { null: false }], null: false, description: 'Columns that may be used as order_by of overview queries, with assigned label values'

    field :ticket_count, Integer, null: false, description: 'Count of tickets the authenticated user may see in this overview'

    field :cached_ticket_count, Integer, null: false do
      description 'Cached count of tickets the authenticated user may see in this overview'

      argument :cache_ttl, Integer do
        description 'How long to cache the overview data, in seconds. This will be part of the cache key so that different durations get different caches.'
      end
    end

    def order_by
      object.order['by']
    end

    def order_direction
      object.order['direction']
    end

    def view_columns_raw
      # Overview column information is saved without the _id suffixes for internal Ticket relation fields.
      # Map them back to the original field names to avoid issues in the front end, until the storage gets improved.
      ticket_columns = ::Ticket.column_names
      flatten_columns(object.view['s']).reject { |field_name| field_name == object.group_by }.map do |field_name|
        ticket_columns.include?(field_name) ? field_name : "#{field_name}_id"
      end
    end

    def view_columns
      flatten_columns(object.view['s']).map do |attribute|
        { key: attribute, value: label_for_attribute(attribute) }
      end
    end

    def order_columns
      columns = flatten_columns(object.view['s'])
      columns.unshift(order_by) if columns.exclude?(order_by)

      columns.map do |attribute|
        { key: attribute, value: label_for_attribute(attribute) }
      end
    end

    def ticket_count
      ::Ticket::Overviews
        .tickets_for_overview(object, context.current_user)
        .unscope(:order)
        .count(:all)
        .count # double-count due to grouping in underlying scope
    end

    def cached_ticket_count(cache_ttl:)
      cache_key = "OverviewType.cached_ticket_count(overview:#{object.id},cache_ttl:#{cache_ttl})-#{object_cache_key(object)}"

      Rails.cache.fetch(cache_key, expires_in: cache_ttl) do
        ticket_count
      end
    end

    private

    VISIBLE_ORDER_BY_NAMES = {
      'number'                       => __('Number'),
      'title'                        => __('Title'),
      'customer'                     => __('Customer'),
      'organization'                 => __('Organization'),
      'group'                        => __('Group'),
      'owner'                        => __('Owner'),
      'state'                        => __('State'),
      'pending_time'                 => __('Pending till'),
      'priority'                     => __('Priority'),
      'article_count'                => __('Article#'),
      'time_unit'                    => __('Accounted Time'),
      'escalation_at'                => __('Escalation at'),
      'first_response_escalation_at' => __('Escalation at (First Response Time)'),
      'update_escalation_at'         => __('Escalation at (Update Time)'),
      'close_escalation_at'          => __('Escalation at (Close Time)'),
      'last_contact_at'              => __('Last contact'),
      'last_contact_agent_at'        => __('Last contact (agent)'),
      'last_contact_customer_at'     => __('Last contact (customer)'),
      'first_response_at'            => __('First response'),
      'close_at'                     => __('Closing time'),
      'created_by'                   => __('Created by'),
      'created_at'                   => __('Created at'),
      'updated_by'                   => __('Updated by'),
      'updated_at'                   => __('Updated at'),
    }.freeze

    def label_for_attribute(attribute)
      @object_attribute_names ||= ::ObjectManager::Object.new('Ticket').attributes(context.current_user).to_h do |object_attribute|
        [object_attribute[:name], object_attribute[:display]]
      end

      VISIBLE_ORDER_BY_NAMES[attribute] || @object_attribute_names[attribute]
    end

    def flatten_columns(columns)
      [ columns ].flatten
    end
  end
end

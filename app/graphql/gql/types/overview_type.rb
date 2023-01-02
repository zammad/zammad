# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class OverviewType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Ticket overviews'

    field :name, String, null: false
    field :link, String, null: false
    field :prio, Integer, null: false
    # field :condition, String, null: false
    # field :order, String, null: false
    field :order_by, String, null: false
    field :order_direction, Gql::Types::Enum::OrderDirectionType, null: false
    # field :group_by, String
    # field :group_direction, String
    # field :organization_shared, Boolean, null: false
    # field :out_of_office, Boolean, null: false
    # field :view, String, null: false
    field :active, Boolean, null: false

    field :view_columns, [Gql::Types::KeyValueType, { null: false }], null: false, description: 'Columns to be shown on screen, with assigned label values'
    field :order_columns, [Gql::Types::KeyValueType, { null: false }], null: false, description: 'Columns that may be used as order_by of overview queries, with assigned label values'
    field :ticket_count, Integer, null: false, description: 'Count of tickets the authenticated user may see in this overview'

    def order_by
      object.order['by']
    end

    def order_direction
      object.order['direction']
    end

    def view_columns
      columns = flatten_columns(object.view['s'])
      columns.map do |attribute|
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
      ::Ticket::Overviews.tickets_for_overview(object, context.current_user).limit(nil).count
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

# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class Channel::Email::AddInputType < Gql::Types::BaseInputObject

    description 'Fields for a new email channel.'

    argument :inbound_configuration, Gql::Types::Input::Channel::Email::InboundConfigurationInputType, 'Configuration to validate'
    argument :outbound_configuration, Gql::Types::Input::Channel::Email::OutboundConfigurationInputType, 'Configuration to validate'
    argument :group_id, GraphQL::Types::ID, loads: Gql::Types::GroupType, required: false, description: 'Group for this channel'
    argument :email_address, String, description: 'Sender email address for this channel'
    argument :email_realname, String, description: 'Sender email realname for this channel'
  end
end

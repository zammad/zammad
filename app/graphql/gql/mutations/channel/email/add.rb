# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Channel::Email::Add < Channel::Email::BaseConfiguration
    description 'Create a new email channel. This does not perform email validation.'

    argument :input, Gql::Types::Input::Channel::Email::AddInputType, 'Fields for the new channel'

    field :channel, Gql::Types::ChannelType, description: 'The new channel object'

    def resolve(input:)
      channel = ::Service::Channel::Email::Create.new.execute(
        inbound_configuration:  map_type_to_config(input.inbound_configuration),
        outbound_configuration: map_type_to_config(input.outbound_configuration),
        group:                  input.group,
        email_address:          input.email_address,
        email_realname:         input.email_realname,
      )

      { channel: }
    end
  end
end

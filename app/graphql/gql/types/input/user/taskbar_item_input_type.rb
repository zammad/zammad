# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::User
  class TaskbarItemInputType < Gql::Types::BaseInputObject
    include Gql::Types::Input::Concerns::ProvidesObjectAttributeValues

    description 'The taskbar item fields.'

    argument :key, String, required: true, description: 'The itaskbar item related object key identifier'
    argument :callback, Gql::Types::Enum::TaskbarEntityType, required: true, description: 'The taskbar item related object callback'
    argument :state, GraphQL::Types::JSON, required: false, description: 'The taskbar item related object state'
    argument :params, GraphQL::Types::JSON, required: false, description: 'The taskbar item related object parameters'
    argument :prio, Integer, required: true, description: 'The taskbar item sorting priority'
    argument :notify, Boolean, required: true, description: 'The taskbar item notification about changes'
    argument :app, Gql::Types::Enum::TaskbarAppType, required: true, description: 'The taskbar item application'
    argument :dirty, Boolean, required: false, description: 'The taskbar item form updater dirty flag'

  end
end

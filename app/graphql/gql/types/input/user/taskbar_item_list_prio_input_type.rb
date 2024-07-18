# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::User
  class TaskbarItemListPrioInputType < Gql::Types::BaseInputObject

    description 'The taskbar item list priority fields.'

    argument :id, GraphQL::Types::ID, required: true, description: 'The taskbar item ID'
    argument :prio, Integer, required: true, description: 'The taskbar item priority'

  end
end

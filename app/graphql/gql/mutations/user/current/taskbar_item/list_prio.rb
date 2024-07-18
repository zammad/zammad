# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::TaskbarItem::ListPrio < BaseMutation

    description 'Sort taskbar item list by priority.'

    argument :list, [Gql::Types::Input::User::TaskbarItemListPrioInputType], required: true, description: 'The taskbar item list fields.'

    field :success, Boolean, description: 'This indicates if sorting the taskbar item list was successful.'

    def resolve(list:)
      list.each do |item|
        begin
          taskbar_item = Gql::ZammadSchema.verified_object_from_id(item.id, type: Taskbar)
        rescue ActiveRecord::RecordNotFound
          next
        end

        taskbar_item.update!(prio: item.prio)
      end

      { success: true }
    end
  end
end

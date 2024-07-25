# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::TaskbarItem::ListPrio < BaseMutation

    description 'Sort taskbar item list by priority.'

    argument :list, [Gql::Types::Input::User::TaskbarItemListPrioInputType], required: true, description: 'The taskbar item list fields.'

    field :success, Boolean, description: 'This indicates if sorting the taskbar item list was successful.'

    def resolve(list:)
      prio = []
      list.each do |item|
        begin
          taskbar_item = Gql::ZammadSchema.verified_object_from_id(item.id, type: Taskbar)
          prio << { id: taskbar_item.id, prio: item.prio }
        rescue ActiveRecord::RecordNotFound
          next
        end
      end

      Taskbar.reorder_list(context.current_user, prio)

      { success: true }
    end
  end
end

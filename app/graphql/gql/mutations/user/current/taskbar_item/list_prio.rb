# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::TaskbarItem::ListPrio < BaseMutation

    description 'Sort taskbar item list by priority.'

    argument :list, [Gql::Types::Input::User::TaskbarItemListPrioInputType], required: true, description: 'The taskbar item list fields.'

    field :success, Boolean, description: 'This indicates if sorting the taskbar item list was successful.'

    def resolve(list:)
      list_with_internal_ids = list.map do |item|
        internal_id = Gql::ZammadSchema.internal_id_from_id(item.id, type: ::Taskbar)

        { id: internal_id, prio: item.prio }
      end

      Taskbar.reorder_list(context.current_user, list_with_internal_ids)

      { success: true }
    end
  end
end

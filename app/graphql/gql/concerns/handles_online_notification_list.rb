# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Shared by the online notification list query and the unseen count subscription:
#   the count only means something if it covers what the list can show.
module Gql::Concerns::HandlesOnlineNotificationList
  extend ActiveSupport::Concern

  private

  # The client asks for the list without a page size and cannot load more, so
  #   the schema's default page size is the window it sees.
  def online_notification_list(user)
    ::OnlineNotification
      .list(user, access: 'ignore', limit: Gql::ZammadSchema.default_page_size)
      .where(object_lookup_id: ::ObjectLookup.where(name: renderable_meta_object_names).select(:id))
  end

  def renderable_meta_object_names
    Gql::Types::ActivityMessageMetaObjectType.possible_types.map { |t| t.name.delete_prefix('Gql::Types::').delete_suffix('Type') }
  end
end

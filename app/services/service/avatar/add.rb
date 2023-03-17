# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::Avatar::Add < Service::BaseWithCurrentUser
  def execute(full_image:, resize_image:)
    Avatar.add(
      object:    'User',
      o_id:      current_user.id,
      full:      {
        content:   full_image[:content],
        mime_type: full_image[:mime_type],
      },
      resize:    {
        content:   resize_image[:content],
        mime_type: resize_image[:mime_type],
      },
      source:    "upload #{Time.zone.now}",
      deletable: true,
    ).tap do |avatar|
      current_user.update!(image: avatar.store_hash)
    end
  end
end

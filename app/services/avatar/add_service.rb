# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Avatar::AddService < BaseService
  def execute(args)
    add(full_image: args[:full_image], resize_image: args[:resize_image])
  end

  private

  def add(full_image:, resize_image:)
    avatar = Avatar.add(
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
    )

    current_user.update!(image: avatar.store_hash)

    avatar
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3829BrokenAvatars < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    object_name = 'User'
    object_id = ObjectLookup.by_name(object_name)

    User.all.pluck(:id, :image_source).each do |user_id, image_source|
      next if image_source.blank?
      next if image_source.match?(%r{\.(?:png|jpg|jpeg)}i)

      avatar = Avatar.where(
        object_lookup_id: object_id,
        o_id:             user_id,
      ).where('source_url LIKE ?', "#{image_source}%").first
      next if avatar.nil?

      Avatar.remove_one(object_name, user_id, avatar.id)
    end
  end
end

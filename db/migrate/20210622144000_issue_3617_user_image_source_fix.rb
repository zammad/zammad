# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue3617UserImageSourceFix < ActiveRecord::Migration[5.2]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    User.where("image_source NOT LIKE 'http%'").find_each do |user|
      user.remove_invalid_image_source
      user.save!
    end
  end
end

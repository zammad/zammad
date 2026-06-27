# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class SignatureConvertImagesToCid < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Signature.find_each do |elem|
      # Migrations run without UserInfo.current_user_id
      # But exporting images to Store requires a user
      UserInfo.with_user_id(elem.updated_by_id) do
        elem.updated_at = Time.current
        elem.save!
      end
    end
  end
end

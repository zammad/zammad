# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class RemoveUnfixableGenericOauth2Login < ActiveRecord::Migration[5.2]
  def change

    return if !Setting.exists?(name: 'system_init_done')

    Setting.where(name: %w[auth_oauth2 auth_oauth2_credentials]).destroy_all
  end
end

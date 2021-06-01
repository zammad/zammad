# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue3085DoorkeeperScopes < ActiveRecord::Migration[5.2]
  def change
    Doorkeeper::AccessGrant.where(scopes: ['', nil]).update_all(scopes: 'full') # rubocop:disable Rails/SkipsModelValidations
  end
end

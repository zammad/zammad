# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class DisablePublicSignup < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # This deployment's only customer-facing UI (vr8-tickets-client) has no
    # signup screen - customer accounts are provisioned another way, so the
    # public self-registration flow (and its 'signup'/'signup_taken_reset'
    # notification emails) is dead weight that's better closed off entirely.
    Setting.set('user_create_account', false)
  end
end

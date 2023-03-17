# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class MoveAuthBackendsToDatabase < ActiveRecord::Migration[6.0]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Authentication via %s',
      name:        'auth_internal',
      area:        'Security::Authentication',
      description: 'Enables user authentication via %s.',
      preferences: {
        title_i18n:       ['internal database'],
        description_i18n: ['internal database'],
        permission:       ['admin.security'],
      },
      state:       {
        priority: 1,
        adapter:  'Auth::Backend::Internal',
      },
      frontend:    false
    )
    Setting.create_if_not_exists(
      title:       'Authentication via %s',
      name:        'auth_developer',
      area:        'Security::Authentication',
      description: 'Enables user authentication via %s.',
      preferences: {
        title_i18n:       ['developer password'],
        description_i18n: ['developer password'],
        permission:       ['admin.security'],
      },
      state:       {
        priority: 2,
        adapter:  'Auth::Backend::Developer',
      },
      frontend:    false
    )

    update_auth_ldap
  end

  private

  def update_auth_ldap # rubocop:disable Metrics/AbcSize

    begin
      auth_ldap = Setting.find_by(name: 'auth_ldap')

      auth_ldap.state_initial[:value][:priority] = 3
      auth_ldap.state_initial[:value][:adapter] = 'Auth::Backend::Ldap'
      auth_ldap.state_current[:value][:priority] = 3
      auth_ldap.state_current[:value][:adapter] = 'Auth::Backend::Ldap'

      auth_ldap.save!
    rescue => e
      Rails.logger.error "Error while updating 'auth_ldap' Setting priority and adapter"
      Rails.logger.error e
    end
  end
end

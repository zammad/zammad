class UpdateAuth < ActiveRecord::Migration
  def up
    Setting.create_or_update(
      title: 'Authentication via OTRS',
      name: 'auth_otrs',
      area: 'Security::Authentication',
      description: 'Enables user authentication via OTRS.',
      state: {
        adapter: 'Auth::Otrs',
        required_group_ro: 'stats',
        group_rw_role_map: {
          'admin' => 'Admin',
          'stats' => 'Report',
        },
        group_ro_role_map: {
          'stats' => 'Report',
        },
        always_role: {
          'Agent' => true,
        },
      },
      frontend: false
    )
    Setting.create_or_update(
      title: 'Authentication via LDAP',
      name: 'auth_ldap',
      area: 'Security::Authentication',
      description: 'Enables user authentication via LDAP.',
      state: {
        adapter: 'Auth::Ldap',
        host: 'localhost',
        port: 389,
        bind_dn: 'cn=Manager,dc=example,dc=org',
        bind_pw: 'example',
        uid: 'mail',
        base: 'dc=example,dc=org',
        always_filter: '',
        always_roles: ['Admin', 'Agent'],
        always_groups: ['Users'],
        sync_params: {
          firstname: 'sn',
          lastname: 'givenName',
          email: 'mail',
          login: 'mail',
        },
      },
      frontend: false
    )
  end
  def down
  end
end
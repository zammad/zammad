# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ldap_source do
    sequence(:name) { |n| "Source #{n}" }
    active          { true }
    created_by_id   { 1 }
    updated_by_id   { 1 }

    trait :with_config do
      preferences do
        {
          'host_url'         => ENV['IMPORT_LDAP_ENDPOINT'],
          'options'          => { 'dc=foo,dc=example,dc=com'=>'dc=foo,dc=example,dc=com' },
          'option'           => 'dc=foo,dc=example,dc=com',
          'base_dn'          => 'dc=foo,dc=example,dc=com',
          'bind_user'        => ENV['IMPORT_LDAP_USER'],
          'bind_pw'          => ENV['IMPORT_LDAP_PASSWORD'],
          'user_uid'         => 'uid',
          'user_filter'      => '(objectClass=posixaccount)',
          'group_uid'        => 'dn',
          'group_filter'     => '(objectClass=posixgroup)',
          'user_attributes'  => { 'cn' => 'firstname', 'sn' => 'lastname', 'mail' => 'email', 'uid' => 'login', 'telephonenumber' => 'phone' },
          'group_role_map'   =>
                                { 'cn=admin,ou=groups,dc=foo,dc=example,dc=com' => ['1'], 'cn=1st level,ou=groups,dc=foo,dc=example,dc=com' => ['2'] },
          'unassigned_users' => 'sigup_roles'
        }
      end
    end
  end
end

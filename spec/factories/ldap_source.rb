# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ldap_source do
    sequence(:name) { |n| "Source #{n}" }
    active          { true }
    created_by_id   { 1 }
    updated_by_id   { 1 }

    prefs = {
      'host'             => ENV['IMPORT_LDAP_ENDPOINT'],
      'ssl'              => 'off',
      'ssl_verify'       => false,
      'options'          => { 'dc=foo,dc=example,dc=com'=>'dc=foo,dc=example,dc=com' },
      'option'           => 'dc=foo,dc=example,dc=com',
      'base_dn'          => 'dc=foo,dc=example,dc=com',
      'bind_user'        => ENV['IMPORT_LDAP_USER'],
      'bind_pw'          => ENV['IMPORT_LDAP_PASSWORD'],
      'user_uid'         => 'uid',
      'user_filter'      => '(objectClass=posixaccount)',
      'group_uid'        => 'dn',
      'group_filter'     => '(objectClass=groupOfNames)',
      'user_attributes'  => { 'cn' => 'firstname', 'sn' => 'lastname', 'mail' => 'email', 'uid' => 'login', 'telephonenumber' => 'phone' },
      'group_role_map'   => { 'cn=admin,ou=groups,dc=foo,dc=example,dc=com' => ['1'], 'cn=1st level,ou=groups,dc=foo,dc=example,dc=com' => ['2'] },
      'unassigned_users' => 'sigup_roles'
    }

    trait :with_config do
      preferences { prefs }
    end

    trait :with_ssl do
      preferences { prefs.merge('ssl' => 'ssl', 'ssl_verify' => false) }
    end

    trait :with_ssl_verified do
      preferences { prefs.merge('ssl' => 'ssl', 'ssl_verify' => true) }
    end

    trait :with_starttls do
      preferences { prefs.merge('ssl' => 'starttls', 'ssl_verify' => false) }
    end

    trait :with_starttls_verified do
      preferences { prefs.merge('ssl' => 'starttls', 'ssl_verify' => true) }
    end
  end
end

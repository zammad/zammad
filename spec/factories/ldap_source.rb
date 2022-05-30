# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
          'wizardData'       =>
                                { 'backend_user_attributes' =>
                                                               { 'dn'              => 'dn (e.g., cn=nb,dc=foo,dc=example,dc=com)',
                                                                 'cn'              => 'cn (e.g., Nicole)',
                                                                 'sn'              => 'sn (e.g., Braun)',
                                                                 'uid'             => 'uid (e.g., nb)',
                                                                 'uidnumber'       => 'uidnumber (e.g., 5000)',
                                                                 'gidnumber'       => 'gidnumber (e.g., 5000)',
                                                                 'userpassword'    => 'userpassword (e.g., testnb)',
                                                                 'homedirectory'   => 'homedirectory (e.g., /home/nb)',
                                                                 'loginshell'      => 'loginshell (e.g., /bin/sh)',
                                                                 'gecos'           => 'gecos (e.g., Comments)',
                                                                 'mail'            => 'mail (e.g., nb@example.com)',
                                                                 'telephonenumber' => 'telephonenumber (e.g., 110)',
                                                                 'roomnumber'      => 'roomnumber (e.g., 0200)' },
                                  'backend_groups'          =>
                                                               { 'cn=admin,ou=groups,dc=foo,dc=example,dc=com'     => 'cn=admin,ou=groups,dc=foo,dc=example,dc=com',
                                                                 'cn=1st level,ou=groups,dc=foo,dc=example,dc=com' => 'cn=1st level,ou=groups,dc=foo,dc=example,dc=com',
                                                                 'cn=2nd level,ou=groups,dc=foo,dc=example,dc=com' => 'cn=2nd level,ou=groups,dc=foo,dc=example,dc=com',
                                                                 'cn=sales,ou=groups,dc=foo,dc=example,dc=com'     => 'cn=sales,ou=groups,dc=foo,dc=example,dc=com' },
                                  'user_attributes'         =>
                                                               { 'login'      => 'Login',
                                                                 'firstname'  => 'First name',
                                                                 'lastname'   => 'Last name',
                                                                 'email'      => 'Email',
                                                                 'web'        => 'Web',
                                                                 'phone'      => 'Phone',
                                                                 'mobile'     => 'Mobile',
                                                                 'fax'        => 'Fax',
                                                                 'department' => 'Department',
                                                                 'address'    => 'Address',
                                                                 'note'       => 'Note' },
                                  'roles'                   => { '1' => 'Admin', '2' => 'Agent', '3' => 'Customer' } },
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

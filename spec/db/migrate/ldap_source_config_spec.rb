# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe LdapSourceConfig, type: :db_migration do
  context 'with existing LDAP sources' do
    let!(:ldap_source) { create(:ldap_source, preferences: preferences) }
    let(:preferences) do
      {
        'host_url'         => host_url,
        'options'          => { 'dc=foo,dc=example,dc=com'=>'dc=foo,dc=example,dc=com' },
        'option'           => 'dc=foo,dc=example,dc=com',
        'base_dn'          => 'dc=foo,dc=example,dc=com',
        'bind_user'        => 'dummy',
        'bind_pw'          => 'dummy',
        'user_uid'         => 'uid',
        'user_filter'      => '(objectClass=posixaccount)',
        'group_uid'        => 'dn',
        'group_filter'     => '(objectClass=posixgroup)',
        'user_attributes'  => { 'cn' => 'firstname', 'sn' => 'lastname', 'mail' => 'email', 'uid' => 'login', 'telephonenumber' => 'phone' },
        'group_role_map'   => { 'cn=admin,ou=groups,dc=foo,dc=example,dc=com' => ['1'], 'cn=1st level,ou=groups,dc=foo,dc=example,dc=com' => ['2'] },
        'unassigned_users' => 'sigup_roles',
      }
    end

    context 'with LDAPS' do
      let(:host_url) { 'ldaps://ldaps.example.com' }

      it 'migrates the LdapSource', :aggregate_failures do
        migrate
        ldap_source.reload

        expect(ldap_source.preferences['host']).to eq('ldaps.example.com')
        expect(ldap_source.preferences['ssl']).to eq('ssl')
        expect(ldap_source.preferences).not_to have_key('host_url')
      end
    end

    context 'with LDAP' do
      let(:host_url) { 'ldap://ldap.example.com' }

      it 'migrates the LdapSource', :aggregate_failures do
        migrate
        ldap_source.reload

        expect(ldap_source.preferences['host']).to eq('ldap.example.com')
        expect(ldap_source.preferences['ssl']).to eq('off')
        expect(ldap_source.preferences).not_to have_key('host_url')
      end
    end

    context 'without host_url' do
      let(:preferences) do
        {
          'host'             => 'ldap.example.com',
          'ssl'              => ssl,
          'options'          => { 'dc=foo,dc=example,dc=com'=>'dc=foo,dc=example,dc=com' },
          'option'           => 'dc=foo,dc=example,dc=com',
          'base_dn'          => 'dc=foo,dc=example,dc=com',
          'bind_user'        => 'dummy',
          'bind_pw'          => 'dummy',
          'user_uid'         => 'uid',
          'user_filter'      => '(objectClass=posixaccount)',
          'group_uid'        => 'dn',
          'group_filter'     => '(objectClass=posixgroup)',
          'user_attributes'  => { 'cn' => 'firstname', 'sn' => 'lastname', 'mail' => 'email', 'uid' => 'login', 'telephonenumber' => 'phone' },
          'group_role_map'   => { 'cn=admin,ou=groups,dc=foo,dc=example,dc=com' => ['1'], 'cn=1st level,ou=groups,dc=foo,dc=example,dc=com' => ['2'] },
          'unassigned_users' => 'sigup_roles',
        }
      end

      context 'with ssl = true' do
        let(:ssl) { true }

        it 'migrates the LdapSource', :aggregate_failures do
          migrate
          ldap_source.reload

          expect(ldap_source.preferences['host']).to eq('ldap.example.com')
          expect(ldap_source.preferences['ssl']).to eq('ssl')
          expect(ldap_source.preferences).not_to have_key('host_url')
        end
      end

      context 'with ssl = false' do
        let(:ssl) { false }

        it 'migrates the LdapSource', :aggregate_failures do
          migrate
          ldap_source.reload

          expect(ldap_source.preferences['host']).to eq('ldap.example.com')
          expect(ldap_source.preferences['ssl']).to eq('off')
          expect(ldap_source.preferences).not_to have_key('host_url')
        end
      end
    end
  end
end

#!/usr/bin/env sh

env

# Ensure proper permissions on root-mounted volumes.
sudo chown -R "${USER}" node_modules .pnpm-store

pnpm setup
export PNPM_HOME="${HOME}/.local/share/pnpm"
export PATH="${PNPM_HOME}:${PATH}"
pnpm config set store-dir "$(pwd)/.pnpm-store" --global

bin/setup --skip-server

echo "== Precompile Ruby cache =="

bundle exec bootsnap precompile --gemfile app/ lib/

echo "== Configure Elasticsearch URL =="

bundle exec rails r "Setting.set('es_url', 'http://elasticsearch:9200')"

echo "== Run auto_wizard setup =="

bundle exec rails zammad:setup:auto_wizard

echo "== Import LDAP CA certificate =="

bundle exec rails r "SSLCertificate.create!(certificate: Rails.root.join('.devcontainer/with-ldap/ldap/certs/ca.crt').read)"

echo "== Configure LDAP source =="

bundle exec rails r "
  Setting.set('ldap_integration', true)
  LdapSource.find_by(name: 'Zammad LDAP')&.destroy
  LdapSource.create!(
    name: 'Zammad LDAP',
    active: true,
    preferences: {
      'host'             => 'ldap',
      'ssl'              => 'ssl',
      'ssl_verify'       => true,
      'options'          => { 'dc=foo,dc=example,dc=com' => 'dc=foo,dc=example,dc=com' },
      'option'           => 'dc=foo,dc=example,dc=com',
      'base_dn'          => 'dc=foo,dc=example,dc=com',
      'bind_user'        => 'cn=admin,dc=foo,dc=example,dc=com',
      'bind_pw'          => 'test',
      'user_uid'         => 'uid',
      'user_filter'      => '(objectClass=posixaccount)',
      'group_uid'        => 'dn',
      'group_filter'     => '(objectClass=groupOfNames)',
      'user_attributes'  => { 'cn' => 'firstname', 'sn' => 'lastname', 'mail' => 'email', 'uid' => 'login', 'telephonenumber' => 'phone' },
      'group_role_map'   => {
        'cn=admin,ou=groups,dc=foo,dc=example,dc=com'     => ['1'],
        'cn=1st level,ou=groups,dc=foo,dc=example,dc=com' => ['2'],
      },
      'unassigned_users' => 'sigup_roles',
    },
    created_by_id: 1,
    updated_by_id: 1,
  )
"

echo "== Rebuild search index =="

bundle exec rails zammad:searchindex:rebuild

echo "== Precompile frontend assets =="

bundle exec rails assets:precompile

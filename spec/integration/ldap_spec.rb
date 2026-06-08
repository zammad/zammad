# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ldap import', integration: true, required_envs: %w[IMPORT_LDAP_ENDPOINT IMPORT_LDAP_USER IMPORT_LDAP_PASSWORD], use_vcr: false do # rubocop:disable RSpec/DescribeClass
  let(:ldap_source) { create(:ldap_source, :with_config) }

  let(:expected_result) do
    { 'skipped'     => 0,
      'created'     => 14,
      'updated'     => 0,
      'unchanged'   => 0,
      'failed'      => 0,
      'deactivated' => 0,
      'sum'         => 14,
      'total'       => 14,
      'role_ids'    =>
                       { 3 =>
                              { 'skipped'     => 0,
                                'created'     => 10,
                                'updated'     => 0,
                                'unchanged'   => 0,
                                'failed'      => 0,
                                'deactivated' => 0,
                                'sum'         => 10,
                                'total'       => 0 },
                         1 =>
                              { 'skipped'     => 0,
                                'created'     => 2,
                                'updated'     => 0,
                                'unchanged'   => 0,
                                'failed'      => 0,
                                'deactivated' => 0,
                                'sum'         => 2,
                                'total'       => 0 },
                         2 =>
                              { 'skipped'     => 0,
                                'created'     => 2,
                                'updated'     => 0,
                                'unchanged'   => 0,
                                'failed'      => 0,
                                'deactivated' => 0,
                                'sum'         => 2,
                                'total'       => 0 } } }
  end

  shared_examples 'ldap import' do
    it 'does import users and roles' do
      expect(ImportJob.last.result).to eq(expected_result)

      user_ab = User.find_by(login: 'ab')
      expect(user_ab.firstname).to eq('Albert')
      expect(user_ab.lastname).to eq('Braun')
      expect(user_ab.email).to eq('ab@example.com')
      expect(user_ab.roles.first.name).to eq('Admin')
      expect(user_ab.roles.count).to eq(1)

      user_lb = User.find_by(login: 'lb')
      expect(user_lb.firstname).to eq('Lena')
      expect(user_lb.lastname).to eq('Braun')
      expect(user_lb.email).to eq('lb@example.com')
      expect(user_lb.roles.first.name).to eq('Agent')
      expect(user_lb.roles.count).to eq(1)
    end
  end

  shared_examples 'certificate verification error' do
    it 'returns certificate verify failed error' do
      expect(ImportJob.last.result[:error]).to match(%r{error: certificate verify failed \(self(-|\s)signed certificate in certificate chain\)})
    end
  end

  context 'when importing' do
    before do
      before_hook if defined? before_hook
      Setting.set('ldap_integration', true)
      TCR.turned_off do
        ldap_source
        ImportJob.start_registered
      end
    end

    include_examples 'ldap import'

    context 'when containing nested groups' do
      let(:ldap_source) do
        ldap_source = create(:ldap_source, :with_config)
        ldap_source.preferences['group_role_map'] = { 'cn=3rd level,ou=groups,dc=foo,dc=example,dc=com' => ['2'], '4th level,ou=groups,dc=foo,dc=example,dc=com' => ['2'] }
        ldap_source.save!
        ldap_source
      end

      it 'does not import agents because no recursive mode on' do
        expect(ImportJob.last.result['role_ids'].dig(2, 'created')).to be_nil
      end

      context 'when 3rd level recursive' do
        let(:ldap_source) do
          ldap_source = create(:ldap_source, :with_config)
          ldap_source.preferences['group_role_map'] = { 'cn=3rd level,ou=groups,dc=foo,dc=example,dc=com' => ['2'], '4th level,ou=groups,dc=foo,dc=example,dc=com' => ['2'] }
          ldap_source.preferences['group_role_recursive'] = { 'cn=3rd level,ou=groups,dc=foo,dc=example,dc=com' => true }
          ldap_source.save!
          ldap_source
        end

        it 'does import agents with recursive mode on' do
          expect(ImportJob.last.result['role_ids'].dig(2, 'created')).to eq(2)
        end
      end
    end

    context 'with ssl' do
      context 'with ssl verification' do
        context 'with trusted certificate' do
          let(:ldap_source) { create(:ldap_source, :with_ssl_verified) }
          let(:before_hook) do
            import_ca_certificate
          end

          include_examples 'ldap import'
        end

        context 'without trusted certificate' do
          let(:ldap_source) { create(:ldap_source, :with_ssl_verified) }

          include_examples 'certificate verification error'
        end
      end

      context 'without ssl verification' do
        let(:ldap_source) { create(:ldap_source, :with_ssl) }

        include_examples 'ldap import'
      end
    end

    context 'with starttls' do
      context 'with ssl verification' do
        context 'with trusted certificate' do
          let(:ldap_source) { create(:ldap_source, :with_starttls_verified) }
          let(:before_hook) do
            import_ca_certificate
          end

          include_examples 'ldap import'
        end

        context 'without trusted certificate' do
          let(:ldap_source) { create(:ldap_source, :with_ssl_verified) }

          include_examples 'certificate verification error'
        end
      end

      context 'without ssl verification' do
        let(:ldap_source) { create(:ldap_source, :with_starttls) }

        include_examples 'ldap import'
      end
    end

    def import_ca_certificate
      # Import CA certificate into the trust store.
      SSLCertificate.create!(certificate: Rails.root.join('spec/fixtures/files/ldap/ca.crt').read)
    end
  end
end

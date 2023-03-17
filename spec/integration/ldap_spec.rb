# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

  context 'when importing' do
    before do
      Setting.set('ldap_integration', true)
      TCR.turned_off do
        ldap_source
        ImportJob.start_registered
      end
    end

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
end

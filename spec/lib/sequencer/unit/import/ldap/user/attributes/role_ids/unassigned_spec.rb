# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Ldap::User::Attributes::RoleIds::Unassigned, sequencer: :unit do
  let(:subject) { process(parameters) }

  let(:parameters) do
    { resource:    resource,
      dn_roles:    dn_roles,
      ldap_config: ldap_config,
      mapped:      mapped,
      instance:    instance }
  end

  let(:resource) do
    { dn:        'uid=jane,ou=People,dc=example,dc=org',
      uid:       'jane_doe',
      sn:        'Doe',
      givenname: 'Jane' }.with_indifferent_access
  end

  # this sequencer unit only runs when this parameter is PRESENT
  let(:dn_roles) do
    { 'uid=john,ou=people,dc=example,dc=org' => [1] }.with_indifferent_access
  end

  # this sequencer unit only runs when this parameter's "unassigned_users" key is "skip_sync"
  let(:ldap_config) do
    { unassigned_users: 'skip_sync' }.with_indifferent_access
  end

  # this sequencer unit only runs when this parameter's "role_ids" key is BLANK
  let(:mapped) do
    { firstname: 'Jane',
      lastname:  'Doe',
      login:     'jane_doe' }.with_indifferent_access
  end

  let(:instance) { create(:agent, mapped) }

  context 'when user exists from previous import' do
    context 'and is active' do
      before { instance.update(active: true) }

      it 'deactivates user (with action: :deactivated)' do
        expect(subject).to include(action: :deactivated)
        expect(instance.reload.active).to be(false)
      end
    end

    context 'and is inactive' do
      before { instance.update(active: false) }

      it 'skips user (with action: :skipped)' do
        expect(subject).to include(action: :skipped)
        expect(instance.reload.active).to be(false)
      end
    end
  end

  context 'when user has not been imported yet' do
    let(:instance) { nil }

    it 'skips user (with action: :skipped)' do
      expect(subject).to include(action: :skipped)
    end
  end

  describe 'parameters' do
    before { allow(instance).to receive(:update).and_call_original }

    context 'without :dn_roles (hash map of LDAP DNs ↔ Zammad role IDs for ALL USERS)' do
      before { parameters[:dn_roles].clear }

      it 'skips user (with NO action)' do
        expect(subject).to include(action: nil)
        expect(instance).not_to have_received(:update)
      end
    end

    context 'with :mapped[:role_ids] (hash map of LDAP attributes ↔ Zammad attributes for GIVEN USER)' do
      before { parameters[:mapped].merge!(role_ids: [2]) }

      it 'skips user (with NO action)' do
        expect(subject).to include(action: nil)
        expect(instance).not_to have_received(:update)
      end
    end

    context 'when :ldap_config[:unassigned_users] != "skip_sync"' do
      before { parameters[:ldap_config].merge!(unassigned_users: 'sigup_roles') }

      it 'skips user (with NO action)' do
        expect(subject).to include(action: nil)
        expect(instance).not_to have_received(:update)
      end
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Ldap::User::HttpLog, sequencer: :unit do
  let(:ldap_source) { create(:ldap_source, name: 'Example LDAP') }
  let(:action)      { :updated }
  let(:dry_run)     { false }
  let(:parameters) do
    {
      dry_run:     dry_run,
      action:      action,
      remote_id:   'guid1337',
      mapped:      { login: 'hans' },
      exception:   nil,
      ldap_config: { id: ldap_source.id },
    }
  end

  it 'logs the source the user was synced from' do
    process(parameters)
    expect(HttpLog.last).to have_attributes(facility: 'ldap', status: 'success', url: "source Example LDAP (#{ldap_source.id}): updated -> guid1337")
  end

  context 'when the sync failed' do
    let(:action)     { :failed }
    let(:parameters) { super().merge(exception: RuntimeError.new('broken')) }

    it 'logs the failure' do
      process(parameters)
      expect(HttpLog.last).to have_attributes(status: 'failed', response: { 'message' => 'broken' })
    end
  end

  context 'when the user is unchanged' do
    let(:action) { :unchanged }

    it 'does not log' do
      expect { process(parameters) }.not_to change(HttpLog, :count)
    end

    context 'with logging of unchanged users switched on for the source' do
      let(:parameters) { super().merge(ldap_config: { id: ldap_source.id, log_unchanged: true }) }

      it 'logs the user' do
        process(parameters)
        expect(HttpLog.last).to have_attributes(url: "source Example LDAP (#{ldap_source.id}): unchanged -> guid1337")
      end
    end

    context 'with logging of unchanged users switched off for the source' do
      let(:parameters) { super().merge(ldap_config: { id: ldap_source.id, log_unchanged: 'false' }) }

      it 'does not log' do
        expect { process(parameters) }.not_to change(HttpLog, :count)
      end
    end
  end

  context 'with a dry run' do
    let(:dry_run) { true }

    it 'does not log' do
      expect { process(parameters) }.not_to change(HttpLog, :count)
    end
  end
end

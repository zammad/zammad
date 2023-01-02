# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Ldap::Sources::Configs, sequencer: :unit do
  let(:import_job) { build_stubbed(:import_job, name: 'Import::Ldap') }

  before do
    create(:ldap_source, preferences: { dummy: true })
    create(:ldap_source, active: false, preferences: { dummy: true })
    create(:ldap_source, preferences: { dummy: true })
  end

  it 'does include active ldap sources' do
    result = process(import_job: import_job, dry_run: false)
    expect(result[:configs].count).to eq(2)
  end

  it 'does include dry run config' do
    dry_config = { dry_run_config: true }
    result = process(import_job: import_job, dry_run: true, ldap_config: dry_config)
    expect(result[:configs].last).to eq(dry_config)
  end

  it 'does replace updated config' do
    dry_config = { dry_run_config: true, id: LdapSource.first.id }
    result = process(import_job: import_job, dry_run: true, ldap_config: dry_config)
    expect(result[:configs].first).to eq(dry_config)
  end
end

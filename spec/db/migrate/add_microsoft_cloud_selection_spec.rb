# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AddMicrosoftCloudSelection, type: :db_migration do
  let(:setting) { Setting.find_by(name: 'auth_microsoft_office365_credentials') }

  before do
    form = setting.options[:form].reject { |field| field[:name] == 'cloud' }
    setting.update!(options: setting.options.merge(form:), state: { app_id: 'client', app_secret: 'secret', app_tenant: 'tenant', require_verified_email_domain: true })
  end

  it 'adds the preset field once without changing credentials or existing form fields', :aggregate_failures do
    previous_state = setting.state
    previous_form = setting.options[:form].deep_dup

    migrate
    migrate

    updated = setting.reload
    expect(updated.state).to eq(previous_state)
    expect(updated.options[:form].reject { |field| field[:name] == 'cloud' }).to eq(previous_form)
    fields = updated.options[:form].select { |field| field[:name] == 'cloud' }
    expect(fields.size).to eq(1)
    expect(fields.first[:default]).to eq('global')
    expect(fields.first[:options].keys).to contain_exactly('global', 'us_gov')
    expect(updated.preferences[:validations]).to include('Setting::Validation::MicrosoftOffice365Credentials')
    names = updated.options[:form].pluck(:name)
    expect(names.index('cloud')).to eq(names.index('app_tenant') + 1)
  end

  it 'preserves an invalid legacy value while registering validation for future edits', :aggregate_failures do
    setting.update_columns(state_current: { value: { 'cloud' => 'custom' } })
    previous_state = setting.reload.state

    migrate

    expect(setting.reload.state).to eq(previous_state)
    expect(setting.preferences[:validations]).to include('Setting::Validation::MicrosoftOffice365Credentials')
  end

  it 'skips a new installation before settings exist', system_init_done: false do
    expect { migrate }.not_to(change { setting.reload.options })
  end
end

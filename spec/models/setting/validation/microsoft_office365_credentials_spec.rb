# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::MicrosoftOffice365Credentials do
  let(:setting_name) { 'auth_microsoft_office365_credentials' }

  before do
    setting = Setting.find_by(name: setting_name)
    setting.update!(preferences: setting.preferences.merge(validations: ['Setting::Validation::MicrosoftOffice365Credentials']))
  end

  [nil, {}, { cloud: 'global' }, { cloud: 'us_gov' }].each do |credentials|
    it "accepts supported or legacy credentials #{credentials.inspect}" do
      expect { Setting.set(setting_name, credentials) }.not_to raise_error
    end
  end

  it 'rejects unsupported cloud values when saving credentials' do
    expect { Setting.set(setting_name, { cloud: 'custom' }) }
      .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Unknown Microsoft cloud.')
  end
end

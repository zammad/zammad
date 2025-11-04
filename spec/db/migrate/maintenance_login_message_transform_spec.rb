# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MaintenanceLoginMessageTransform, type: :db_migration do
  let(:setting) { Setting.find_by(name: 'maintenance_login_message') }

  before do
    setting.preferences.delete(:transformations)
    setting.save!
  end

  it 'adds transformation to preferences' do
    migrate

    setting.reload

    expect(setting).to have_attributes(
      preferences: include(
        transformations: contain_exactly('Setting::Transformation::SanitizeHtml')
      )
    )
  end

  it 'transforms existing value' do
    Setting.set('maintenance_login_message', '<b>Bold</b> <i>Italic</i> <img src="fishing.jpg">')

    expect { migrate }
      .to change { Setting.get('maintenance_login_message') }
      .to('<b>Bold</b> <i>Italic</i>')
  end
end

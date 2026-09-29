# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue6237ImportModeSettingDescription, type: :db_migration do
  let(:setting) { Setting.find_by(name: 'import_mode') }

  def stored_description
    Setting.find_by(name: 'import_mode').description
  end

  context 'when the setting still carries the previous description' do
    before do
      setting.update!(description: described_class::PREVIOUS_DESCRIPTION)
    end

    it 'updates the description' do
      expect { migrate }
        .to change { stored_description }
        .from(described_class::PREVIOUS_DESCRIPTION)
        .to('Puts Zammad into import mode. This disables some triggers and denies access to all users without the permission "admin.maintenance".')
    end
  end

  context 'when the description was already updated' do
    before do
      setting.update!(description: described_class::NEW_DESCRIPTION)
    end

    it 'does not change the description' do
      expect { migrate }.not_to change { stored_description }
    end
  end

  context 'when the description was customized' do
    before do
      setting.update!(description: 'Custom description.')
    end

    it 'keeps the customized description' do
      expect { migrate }.not_to change { stored_description }
    end
  end
end

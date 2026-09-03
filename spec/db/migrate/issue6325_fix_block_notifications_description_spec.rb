# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue6325FixBlockNotificationsDescription, type: :db_migration do
  let(:setting) { Setting.find_by(name: 'send_no_auto_response_reg_exp') }

  def stored_description
    Setting.find_by(name: 'send_no_auto_response_reg_exp').description
  end

  context 'when the setting still carries the previous description' do
    before do
      setting.update!(description: described_class::PREVIOUS_DESCRIPTION)
    end

    it 'corrects the description' do
      expect { migrate }
        .to change { stored_description }
        .from(described_class::PREVIOUS_DESCRIPTION)
        .to('If this regex matches, no notification will be sent to the sender.')
    end
  end

  context 'when the description was already corrected' do
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

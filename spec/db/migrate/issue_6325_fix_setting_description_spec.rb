# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue6325FixSettingDescription, type: :db_migration do
  let(:setting) { Setting.find_by(name: 'send_no_auto_response_reg_exp') }

  context 'when having the old description text' do
    before do
      setting.update!(description: 'If this regex matches, no notification will be sent by the sender.')
    end

    it 'updates the description text of send_no_auto_response_reg_exp' do
      expect { migrate }.to change { setting.reload.description }
        .to('If this regex matches, no notification will be sent to the sender.')
    end
  end
end

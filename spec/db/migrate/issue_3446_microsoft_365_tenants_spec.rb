# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3446Microsoft365Tenants, type: :db_migration do
  context 'when having pre-tenant setting' do
    before do
      setting.options['form'] = setting.options['form'].slice 0, 2
      setting.save!
    end

    let(:setting) { Setting.find_by(name: 'auth_microsoft_office365_credentials') }

    it 'adds tenant field to form options' do
      expect { migrate }
        .to change { setting.reload.options['form'].last['name'] }
        .to('app_tenant')
    end

    it 'changes form fields count from 2 to 3 ' do
      expect { migrate }
        .to change { setting.reload.options['form'].count }
        .from(2)
        .to(3)
    end
  end
end

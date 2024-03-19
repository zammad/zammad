# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue5091TimezoneDefault, type: :db_migration do
  subject(:setting) { Setting.find_by(name: 'timezone_default') }

  describe 'timezone value' do
    context 'when timezone_default is empty' do
      before do
        setting.state_current = { value: nil }
        setting.save!(validate: false)
      end

      it 'sets timezone_default to UTC' do
        migrate

        expect(setting.reload.state_current).to include(value: 'UTC')
      end
    end

    context 'when timezone_default is present' do
      let(:sample_tz) { 'Europe/Vilnius' }

      before do
        setting.state_current = { value: sample_tz }
        setting.save(validate: false)
      end

      it 'does not change timezone_default' do
        migrate

        expect(setting.reload.state_current).to include(value: sample_tz)
      end
    end
  end

  describe 'validations preferences' do
    before do
      setting.preferences = {}
      setting.save!
    end

    it 'adds validations preference' do
      migrate

      expect(setting.reload.preferences)
        .to include('validations' => include('Setting::Validation::TimeZone'))
    end
  end
end

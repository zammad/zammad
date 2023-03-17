# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4322SessionTimeoutStringify, type: :db_migration do
  let(:setting)          { Setting.find_by name: 'session_timeout' }
  let(:old_time_options) { [ { value: '0', name: 'disabled' }, { value: 1.hour.seconds, name: __('1 hour') }, { value: 2.hours.seconds, name: __('2 hours') } ] }
  let(:new_time_options) { [ { value: '0', name: 'disabled' }, { value: 1.hour.seconds.to_s, name: __('1 hour') }, { value: 2.hours.seconds.to_s, name: __('2 hours') } ] }
  let(:old_values)       { { value: { 'default' => 4.weeks.seconds.to_s, 'admin'   => 4.weeks.seconds, } } }
  let(:new_values)       { { value: { 'default' => 4.weeks.seconds.to_s, 'admin'   => 4.weeks.seconds.to_s, } } }

  before do
    setting.update!(
      options:       build_setting_options(old_time_options),
      state_current: old_values,
      state_initial: old_values
    )
  end

  it 'changes from integer to string values' do
    migrate

    setting.reload

    expect(setting).to have_attributes(
      options:       build_setting_options(new_time_options),
      state_current: new_values,
      state_initial: new_values,
    )
  end

  def build_setting_options(time_options)
    {
      form: [
        {
          display:   __('Default'),
          null:      false,
          name:      'default',
          tag:       'select',
          options:   time_options,
          translate: true,
        },
        {
          display:   __('admin'),
          null:      false,
          name:      'admin',
          tag:       'select',
          options:   time_options,
          translate: true,
        },
      ]
    }
  end
end

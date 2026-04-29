# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue6056NoProxy, type: :db_migration do
  let(:setting) { Setting.find_by(name: 'proxy_no') }

  before do
    reset_setting
  end

  context 'when the value was not changed' do
    before do
      setting.update!(state_current: setting.state_initial)
    end

    it 'updates current value' do
      expect { migrate }
        .to change { setting.reload.state_current }
        .from(setting.state_initial).to({ value: '' })
    end
  end

  context 'when the value was changed' do
    before do
      setting.update!(state_current: { value: 'localhost,additional.domain.com' })
    end

    it 'does not update current value' do
      expect { migrate }
        .not_to change { setting.reload.state_current }
    end
  end

  it 'updates other attributes' do
    migrate

    expect(setting.reload).to have_attributes(
      description:   'No proxy for these comma-separated addresses. Supports wildcards like *.example.com. Note: Loopback addresses are always excluded from proxying.',
      state_initial: { 'value' => '' },
      options:       include(
        'form' => include(
          include('placeholder' => 'example.com,*.example.org'),
        )
      )
    )
  end

  def reset_setting
    setting.update!(
      description:   __('No proxy for the following hosts.'),
      options:       {
        form: [
          {
            display: '',
            null:    false,
            name:    'proxy_no',
            tag:     'input',
          },
        ],
      },
      state_initial: { value: 'localhost,127.0.0.0,::1' },
    )
  end
end

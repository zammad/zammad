# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Maintenance', type: :system do
  it 'switch maintenance_login on' do
    Setting.set 'maintenance_login', false

    visit 'system/maintenance'
    refresh # ensure changed Setting is loaded

    find('.js-loginSetting label').click
    find('.js-loginSetting input', visible: :all).check # required for chrome

    wait(10).until { expect(Setting.get('maintenance_login')).to be true }
  end

  it 'switch maintenance_login off' do
    Setting.set 'maintenance_login', true

    visit 'system/maintenance'
    refresh # ensure changed Setting is loaded

    find('.js-loginSetting label').click
    find('.js-loginSetting input', visible: :all).uncheck # required for chrome

    wait(10).until { expect(Setting.get('maintenance_login')).to be false }
  end

  it 'shows current maintenance_login_message' do
    message = "badum tssss #{rand(99_999)}"

    Setting.set 'maintenance_login_message', message

    visit 'system/maintenance'
    refresh # ensure changed Setting is loaded

    expect(find('.js-loginPreview [data-name="message"]')).to have_text message
  end

  it 'saves new maintenance_login_message' do
    message_prefix = 'badum'
    message_suffix = "tssss#{rand(99_999)}"

    Setting.set 'maintenance_login_message', message_prefix

    visit 'system/maintenance'
    refresh # ensure changed Setting is loaded

    within(:active_content) do
      elem = find('#maintenance-message.hero-unit')
      elem.click
      elem.send_keys message_suffix
      elem.execute_script "$(this).trigger('blur')" # required for chrome
    end

    find('#global-search').click # unfocus

    wait(10).until { expect(Setting.get('maintenance_login_message')).to eq "#{message_prefix}#{message_suffix}" }
  end
end

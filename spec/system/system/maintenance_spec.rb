# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'System > Maintenance', type: :system do
  context 'when maintenance login is used' do
    context 'when maintenance login will be activated', authenticated_as: :authenticate do
      def authenticate
        Setting.set('maintenance_login', false)
        true
      end

      it 'switch maintenance_login on' do
        visit 'system/maintenance'

        click '.js-loginSetting label'

        wait.until { expect(Setting.get('maintenance_login')).to be true }
      end
    end

    context 'when maintenance login will be deactiavted', authenticated_as: :authenticate do
      def authenticate
        Setting.set('maintenance_login', true)
        true
      end

      it 'switch maintenance_login off' do
        visit 'system/maintenance'

        click '.js-loginSetting label'

        wait.until { expect(Setting.get('maintenance_login')).to be false }
      end
    end

    context 'when maintenance login message will be used', authenticated_as: :authenticate do
      def message
        @message ||= 'badum tssss'
      end

      def authenticate
        Setting.set('maintenance_login_message', message)
        true
      end

      it 'shows current maintenance_login_message' do
        visit 'system/maintenance'

        expect(find('.js-loginPreview [data-name="message"]')).to have_text message
      end

      it 'saves new maintenance_login_message' do
        message_suffix = 'tssss'

        visit 'system/maintenance'

        within(:active_content) do
          elem = find('#maintenance-message.hero-unit')
          elem.click
          elem.send_keys message_suffix
          elem.execute_script "$(this).trigger('blur')" # required for chrome
        end

        find_by_id('global-search').click # unfocus

        wait.until { expect(Setting.get('maintenance_login_message')).to eq "#{message}#{message_suffix}" }
      end
    end
  end

  context 'when maintenance mode is used' do
    context 'when maintenance mode will be activated', authenticated_as: :authenticate do
      def authenticate
        Setting.set('maintenance_mode', false)
        true
      end

      it 'switch maintenance_mode on' do
        visit 'system/maintenance'

        click '.js-modeSetting label'

        in_modal do
          click '.js-submit'
        end

        wait.until { expect(Setting.get('maintenance_mode')).to be true }
      end
    end

    context 'when maintenance mode will be deactiavted', authenticated_as: :authenticate do
      def authenticate
        Setting.set('maintenance_mode', true)
        true
      end

      it 'switch maintenance_mode off' do
        visit 'system/maintenance'

        click '.js-modeSetting label'

        wait.until { expect(Setting.get('maintenance_mode')).to be false }
      end
    end
  end
end

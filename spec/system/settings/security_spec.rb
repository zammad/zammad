# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Settings > Security', type: :system do
  describe 'configure third-party applications' do
    shared_examples 'for third-party applications button in login page' do |**args|
      context "for third-party applications button in login page #{args.empty? ? '' : args.to_s}", authenticated_as: false do
        let(:display_name) { args[:display_name] || app_name }

        before do
          Setting.set("#{app_setting}_credentials", { display_name: args[:display_name] }) if args[:display_name]
        end

        context 'when feature is on' do
          before { Setting.set(app_setting, true) }

          it 'has authentication button in login page' do
            visit 'login'
            expect(page).to have_button(display_name)
          end
        end

        context 'when feature is off' do
          before { Setting.set(app_setting, false) }

          it 'does not have authentication button in login page' do
            visit 'login'
            expect(page).to have_no_button(display_name)
          end
        end
      end
    end

    shared_examples 'for third-party applications settings' do
      context 'for third-party applications settings', authenticated_as: true do
        let(:app_checkbox) { "setting-#{app_setting}" }

        context 'when app is turned on in setting page' do
          before do
            Setting.set(app_setting, false)
            visit '/#settings/security'

            within :active_content do
              click 'a[href="#third_party_auth"]'
            end

            check app_checkbox, allow_label_click: true
            await_empty_ajax_queue
          end

          it 'sets settings to be true' do
            expect(Setting.get(app_setting)).to be_truthy
          end
        end

        context 'when app is turned off in setting page' do
          before do
            Setting.set(app_setting, true)
            visit '/#settings/security'

            within :active_content do
              click 'a[href="#third_party_auth"]'
            end

            uncheck app_checkbox, allow_label_click: true
            await_empty_ajax_queue
          end

          it 'sets settings to be false' do
            expect(Setting.get(app_setting)).to be_falsey
          end
        end
      end
    end

    shared_examples 'Display callback urls for third-party applications #3622' do
      def callback_url
        page.evaluate_script("$('[data-name=#{app_setting}]').closest('.page-header').parent().find('[data-attribute-name=callback_url] input').val()")
      end

      context 'Display callback urls for third-party applications #3622', authenticated_as: true do
        before do
          visit '/#settings/security'
          within :active_content do
            click 'a[href="#third_party_auth"]'
          end
        end

        it 'does have a filled callback url' do
          expect(callback_url).to be_present
        end
      end
    end

    describe 'Authentication via Facebook' do
      let(:app_name)    { 'Facebook' }
      let(:app_setting) { 'auth_facebook' }

      include_examples 'for third-party applications button in login page'
      include_examples 'for third-party applications settings'
      include_examples 'Display callback urls for third-party applications #3622'
    end

    describe 'Authentication via Github' do
      let(:app_name) { 'GitHub' }
      let(:app_setting) { 'auth_github' }

      include_examples 'for third-party applications button in login page'
      include_examples 'for third-party applications settings'
      include_examples 'Display callback urls for third-party applications #3622'
    end

    describe 'Authentication via GitLab' do
      let(:app_name) { 'GitLab' }
      let(:app_setting) { 'auth_gitlab' }

      include_examples 'for third-party applications button in login page'
      include_examples 'for third-party applications settings'
      include_examples 'Display callback urls for third-party applications #3622'
    end

    describe 'Authentication via Google' do
      let(:app_name) { 'Google' }
      let(:app_setting) { 'auth_google_oauth2' }

      include_examples 'for third-party applications button in login page'
      include_examples 'for third-party applications settings'
      include_examples 'Display callback urls for third-party applications #3622'
    end

    describe 'Authentication via LinkedIn' do
      let(:app_name) { 'LinkedIn' }
      let(:app_setting) { 'auth_linkedin' }

      include_examples 'for third-party applications button in login page'
      include_examples 'for third-party applications settings'
      include_examples 'Display callback urls for third-party applications #3622'
    end

    describe 'Authentication via Microsoft' do
      let(:app_name) { 'Microsoft' }
      let(:app_setting) { 'auth_microsoft_office365' }

      include_examples 'for third-party applications button in login page'
      include_examples 'for third-party applications settings'
      include_examples 'Display callback urls for third-party applications #3622'
    end

    describe 'Authentication via SAML' do
      let(:app_name) { 'SAML' }
      let(:app_setting) { 'auth_saml' }

      include_examples 'for third-party applications button in login page'
      include_examples 'for third-party applications button in login page', display_name: 'Security Assertion Markup Language'
      include_examples 'for third-party applications settings'
      include_examples 'Display callback urls for third-party applications #3622'
    end

    describe 'Authentication via SSO' do
      let(:app_name)    { 'SSO' }
      let(:app_setting) { 'auth_sso' }

      include_examples 'for third-party applications button in login page'
      include_examples 'for third-party applications settings'
    end

    describe 'Authentication via Twitter' do
      let(:app_name) { 'Twitter' }
      let(:app_setting) { 'auth_twitter' }

      include_examples 'for third-party applications button in login page'
      include_examples 'for third-party applications settings'
      include_examples 'Display callback urls for third-party applications #3622'
    end

    describe 'Authentication via Weibo' do
      let(:app_name) { 'Weibo' }
      let(:app_setting) { 'auth_weibo' }

      include_examples 'for third-party applications button in login page'
      include_examples 'for third-party applications settings'
      include_examples 'Display callback urls for third-party applications #3622'
    end
  end
end

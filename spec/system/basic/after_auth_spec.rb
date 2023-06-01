# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'system/examples/security_keys_setup_examples'
require 'system/examples/authenticator_app_setup_examples'

RSpec.describe 'After Auth', type: :system do
  context 'with after auth module for 2FA', authenticated_as: :agent do
    let(:agent) { create(:agent, roles: [role]) }
    let(:role)  { create(:role, :agent, name: '2FA') }

    before do
      Setting.set('two_factor_authentication_enforce_role_ids', [role.id])
      Setting.set('two_factor_authentication_method_authenticator_app', true)
    end

    shared_examples 'showing the modal' do
      it 'shows the modal' do
        expect_current_route 'dashboard'

        in_modal do
          expect(page).to have_text('Set up two-factor authentication')
        end
      end
    end

    context 'when logging in', authenticated_as: false do
      before do
        login(
          username: agent.login,
          password: 'test',
        )
      end

      it_behaves_like 'showing the modal'
    end

    context 'when already logged in' do
      before do
        visit '/'
      end

      it_behaves_like 'showing the modal'

      context 'with security keys method' do
        before do
          click_button 'Security Keys'
        end

        include_examples 'security keys setup' do
          let(:password_check) { false }
        end
      end

      context 'with authenticator app method' do
        before do
          click_button 'Authenticator App'
        end

        include_examples 'authenticator app setup' do
          let(:password_check) { false }
        end
      end
    end
  end
end

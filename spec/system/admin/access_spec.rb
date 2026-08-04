# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/admin_role_test.rb (test_role_admin_user).
RSpec.describe 'Admin area access via role permissions', authenticated_as: :authenticate, type: :system do
  let(:agent) { create(:agent) }

  before do
    visit '/'
  end

  context 'when the agent role has no admin permission' do
    def authenticate
      agent
    end

    it 'does not offer the admin area' do
      expect(page).to have_no_link(href: '#manage')
    end
  end

  context 'when the agent role gains admin.user' do
    def authenticate
      Role.find_by(name: 'Agent').permission_grant('admin.user')
      agent
    end

    it 'offers the admin area and allows creating a user' do
      expect(page).to have_link(href: '#manage')

      visit '#manage/users'

      within(:active_content) do
        find('[data-type=new]').click

        find('[name=firstname]').fill_in with: 'AdminUserPermission'
        find('[name=lastname]').fill_in with: 'Test'
        find('span.label-text', text: 'Customer').first(:xpath, './/..').click

        click '.js-submit'

        expect(page).to have_css('table td', text: 'AdminUserPermission')
      end
    end
  end
end

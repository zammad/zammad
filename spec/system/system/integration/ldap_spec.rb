# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Integration > Ldap', type: :system do
  before do
    visit 'system/integration/ldap'
  end

  def open_ldap_wizard
    click_on 'New Source'

    modal_ready
  end

  context 'when new source will be added with the wizard' do
    context 'when no anonymous bind is allowed' do
      it 'can insert base dn in normal text field' do
        open_ldap_wizard

        in_modal do
          fill_in 'name', with: 'Example LDAP'
          fill_in 'host', with: 'example.ldap.okta.com'

          click_on 'Connect'

          wait.until { find('input[name="base_dn"]').present? }

          fill_in 'base_dn', with: 'dc=example,dc=okta,dc=com'

          click '.js-close'
        end
      end
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Integration > Ldap', type: :system do
  def open_ldap_wizard
    click_on 'New Source'

    modal_ready
  end

  context 'when new source will be added with the wizard' do
    before do
      visit 'system/integration/ldap'
    end

    context 'when no anonymous bind is allowed' do
      before do
        allow(Ldap).to receive(:new).and_raise(Net::LDAP::Error, '50, Insufficient Access Rights')
      end

      it 'can insert base dn in normal text field' do
        open_ldap_wizard

        in_modal do
          fill_in 'name', with: 'Example LDAP'
          fill_in 'host', with: 'example.ldap.okta.com'

          click_on 'Connect'

          expect(page).to have_field('base_dn', with: '', class: 'form-control--small')
          expect(page).to have_no_field('base_dn', class: 'ui-autocomplete-input')

          fill_in 'base_dn', with: 'dc=example,dc=okta,dc=com'
          expect(page).to have_field('base_dn', with: 'dc=example,dc=okta,dc=com')

          click '.js-close'
        end

        expect(Ldap).to have_received(:new)
      end
    end
  end

  context 'when a dry run was interrupted by a restart of the background worker (#6334)' do
    let(:ldap_source) do
      create(:ldap_source, :with_config).tap do |source|
        # the factory takes the host from ENV['IMPORT_LDAP_ENDPOINT'], which is only
        # set up for the LDAP integration tests
        source.preferences['host'] = 'ldap.example.com'
        source.save!
      end
    end

    before do
      ldap_source
      create(:import_job, :interrupted,
             name:    'Import::Ldap',
             dry_run: true,
             payload: { ldap_config: ldap_source.preferences },
             result:  { sum: 150, total: 1000 })

      visit 'system/integration/ldap'
    end

    it 'the admin can dismiss the wizard and configure the source again' do
      find("tr[data-id='#{ldap_source.id}']").click

      in_modal disappears: true do
        click '.js-close'
      end

      expect(page).to have_button('Change', disabled: false)
    end
  end
end

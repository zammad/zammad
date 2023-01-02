# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'system/apps/mobile/examples/core_workflow_examples'

RSpec.describe 'Mobile > Organization > Can edit organization', app: :mobile, type: :system do
  let(:organization)        { create(:organization, domain: 'domain.com', note: '') }
  let(:user)                { create(:customer, organization: organization) }
  let(:group)               { create(:group) }
  let(:agent)               { create(:agent, groups: [group]) }

  def open_organization
    visit "/organizations/#{organization.id}"
    wait_for_gql('apps/mobile/entities/organization/graphql/queries/organization.graphql')
  end

  def save_organization(form_updater_call_number = 2)
    wait_for_form_updater(form_updater_call_number)
    click('button:not(disabled)', text: 'Save')
  end

  context 'when visiting as agent', authenticated_as: :agent do
    it 'can edit organization' do
      open_organization

      click('button', text: 'Edit')
      wait_for_form_to_settle('organization-edit')

      within('#dialog-organization-edit') do
        find('[name="note"]').click.send_keys('edit field')

        save_organization
      end

      wait_for_gql('apps/mobile/entities/organization/graphql/mutations/update.graphql')

      organization.reload

      expect(organization.note).to eq('<p>edit field</p>')
    end

    it 'can edit organization with object atrributes', db_strategy: :reset do
      screens = { edit: { 'ticket.agent': { shown: true, required: false } } }
      attribute = create_attribute(
        :object_manager_attribute_text,
        object_name: 'Organization',
        display:     'Custom Text',
        screens:     screens
      )

      open_organization

      click('button', text: 'Edit')
      wait_for_form_to_settle('organization-edit')

      wait_for_form_updater(1)
      within('#dialog-organization-edit') do
        fill_in('name', with: 'new name')
        wait_for_form_updater(2)
        fill_in(attribute.name, with: 'some text')

        save_organization(3)
      end

      wait_for_gql('apps/mobile/entities/organization/graphql/mutations/update.graphql')

      organization.reload
      expect(organization.name).to eq('new name')
      expect(organization[attribute.name]).to eq('some text')
    end
  end

  describe 'Core Workflow' do
    include_examples 'core workflow' do
      let(:object_name) { 'Organization' }
      let(:before_it) do
        lambda {
          open_organization

          click('button', text: 'Edit')
          wait_for_form_to_settle('organization-edit')
        }
      end
    end
  end
end

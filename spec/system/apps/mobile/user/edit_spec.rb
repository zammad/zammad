# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'system/apps/mobile/examples/core_workflow_examples'

RSpec.describe 'Mobile > User > Can edit user', app: :mobile, type: :system do
  let(:organization)        { create(:organization) }
  let(:user)                { create(:customer, firstname: 'Blanche', lastname: 'Devereaux', organization: organization, address: 'Berlin') }
  let(:group)               { create(:group) }
  let(:agent)               { create(:agent, groups: [group]) }

  def open_user
    visit "/users/#{user.id}"
    wait_for_gql('apps/mobile/entities/user/graphql/queries/user.graphql')
  end

  # TODO: add normal edit tests

  describe 'Core Workflow' do
    include_examples 'core workflow' do
      let(:object_name) { 'User' }
      let(:form_updater_gql_number) { 1 }
      let(:before_it) do
        lambda {
          open_user

          click('button', text: 'Edit')
          wait_for_form_to_settle('user-edit')
        }
      end
    end
  end
end

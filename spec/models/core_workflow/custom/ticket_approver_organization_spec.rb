# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/core_workflow/base'

# The `approver` ticket attribute (a User select) must only offer users that
# belong to the same organization as the ticket requester. This is driven by
# CoreWorkflow::Attributes::User#values, applied as a restrict_values default
# on every Ticket core workflow run.
RSpec.describe 'CoreWorkflow > ticket approver limited to requester organization', db_strategy: :reset, type: :model do
  include_context 'with core workflow base'

  let(:organization1) { create(:organization) }
  let(:organization2) { create(:organization) }

  let(:org1_customer) { create(:customer, organization: organization1) }
  let(:org1_lead)     { create(:customer, organization: organization1) }
  let(:org2_customer) { create(:customer, organization: organization2) }
  let(:org2_lead)     { create(:customer, organization: organization2) }

  before do
    UserInfo.current_user_id = 1
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'approver',
      display:     'Approver',
      data_type:   'select',
      data_option: {
        'default'    => '',
        'relation'   => 'User',
        'options'    => {},
        'nulloption' => true,
        'multiple'   => false,
        'null'       => true,
        'translate'  => false,
      },
      editable:    true,
      active:      true,
      screens:     {
        'create_middle' => { '-all-' => { 'null' => true } },
        'edit'          => { '-all-' => { 'null' => true } },
      },
      to_create:   true,
      to_migrate:  true,
      to_delete:   false,
      position:    1500,
    )
    ObjectManager::Attribute.migration_execute

    # make sure both orgs and their members exist before the workflow runs
    org1_customer && org1_lead && org2_customer && org2_lead
  end

  def approver_restrict_values
    result[:restrict_values]['approver']
  end

  # The field allows "no approver", so an empty option is always present.
  context 'when a customer creates their own ticket' do
    let(:result) { CoreWorkflow.perform(payload: payload, user: org1_customer) }

    it 'offers members of the customer organization' do
      expect(approver_restrict_values).to include(org1_customer.id.to_s, org1_lead.id.to_s)
    end

    it 'does not offer members of another organization' do
      expect(approver_restrict_values).not_to include(org2_customer.id.to_s, org2_lead.id.to_s)
    end
  end

  context 'when an agent creates a ticket for a customer' do
    let(:payload) { base_payload.merge('params' => { 'customer_id' => org2_customer.id }) }

    it 'offers members of the selected customer organization' do
      expect(approver_restrict_values).to include(org2_customer.id.to_s, org2_lead.id.to_s)
    end

    it 'does not offer members of a different organization' do
      expect(approver_restrict_values).not_to include(org1_customer.id.to_s, org1_lead.id.to_s)
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/can_csv_import_examples'
require 'models/concerns/can_csv_import_organization_examples'
require 'models/concerns/has_history_examples'
require 'models/concerns/has_search_index_backend_examples'
require 'models/concerns/has_xss_sanitized_note_examples'
require 'models/concerns/has_image_sanitized_note_examples'
require 'models/concerns/has_object_manager_attributes_examples'
require 'models/concerns/has_taskbars_examples'
require 'models/concerns/has_recent_closes_examples'
require 'models/concerns/has_recent_views_examples'

RSpec.describe Organization, type: :model do
  subject(:organization) { create(:organization) }

  it_behaves_like 'ApplicationModel', can_assets: { associations: :members }
  it_behaves_like 'CanCsvImport', unique_attributes: 'name'
  include_examples 'CanCsvImport - Organization specific tests'
  it_behaves_like 'HasHistory'
  it_behaves_like 'HasSearchIndexBackend', indexed_factory: :organization
  it_behaves_like 'HasXssSanitizedNote', model_factory: :organization
  it_behaves_like 'HasImageSanitizedNote', model_factory: :organization
  it_behaves_like 'HasObjectManagerAttributes'
  it_behaves_like 'HasTaskbars'
  it_behaves_like 'HasRecentCloses'
  it_behaves_like 'HasRecentViews'

  describe 'Class methods:' do
    describe '.where_or_cis' do
      it 'finds instance by querying multiple attributes case insensitive' do
        # search for Zammad Foundation
        organizations = described_class.where_or_cis(%i[name note], '%zammad%')
        expect(organizations).not_to be_blank
      end
    end

    describe '.destroy' do

      let!(:refs_known) { { 'Ticket' => { 'organization_id'=> 1 }, 'User' => { 'organization_id'=> 1 } } }
      let!(:user)       { create(:customer, organization: organization) }
      let!(:ticket)     { create(:ticket, organization: organization, customer: user) }

      it 'checks known refs' do
        refs_organization = Models.references('Organization', organization.id, true)
        expect(refs_organization).to eq(refs_known)
      end

      context 'with associations' do
        it 'checks user deletion' do
          organization.destroy(associations: true)
          expect { user.reload }.to raise_exception(ActiveRecord::RecordNotFound)
        end

        it 'checks ticket deletion' do
          organization.destroy(associations: true)
          expect { ticket.reload }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end

      context 'without associations' do
        it 'checks user deletion' do
          organization.destroy
          expect(user.reload.organization_id).to be_nil
        end

        it 'checks ticket deletion' do
          organization.destroy
          expect(ticket.reload.organization_id).to be_nil
        end
      end

      describe 'when changes for member_ids' do
        let(:agent1) { create(:agent) }
        let(:agent2)              { create(:agent) }
        let(:agent3)              { create(:agent) }
        let(:organization_agents) { create(:organization, member_ids: [agent1.id, agent2.id, agent3.id]) }

        it 'does not delete users' do
          organization_agents.update(member_ids: [agent1.id, agent2.id])
          expect { agent3.reload }.not_to raise_error
        end
      end
    end
  end

  describe 'Callbacks, Observers, & Async Transactions -' do
    describe 'Touching associations on update:' do
      let!(:member) { create(:customer, organization: organization) }
      let!(:member_ticket) { create(:ticket, customer: member) }

      context 'when member associations are added' do
        let(:user) { create(:customer) }

        it 'is touched, and touches its other members (but not their tickets)' do
          expect { organization.members.push(user) }
            .to change { organization.reload.updated_at }
        end
      end
    end
  end

  describe '#domain_assignment' do
    it 'fails if enabled and domain is missing' do
      organization.domain_assignment = true
      organization.domain = nil
      organization.valid?

      expect(organization.errors[:domain]).to be_present
    end

    it 'succeeds if enabled and domain is present' do
      organization.domain_assignment = true
      organization.domain = 'example.org'
      organization.valid?

      expect(organization.errors[:domain]).to be_empty
    end

    it 'succeeds if disabled and domain is missing' do
      organization.domain_assignment = false
      organization.domain = nil
      organization.valid?

      expect(organization.errors[:domain]).to be_empty
    end
  end

  describe 'Updating organization members' do
    # the member and organization associations are only part of the attributes for privileged
    # callers, while these examples are about cache invalidation
    around do |example|
      UserInfo.with_system_context { example.run }
    end

    context 'when member gets removed' do
      let(:customer) { create(:customer, organization: organization) }

      before do
        customer.attributes_with_association_ids
        organization.attributes_with_association_ids
      end

      it 'does clear cache of customer after user unassignment' do
        organization.update(member_ids: [])
        expect(customer.reload.attributes_with_association_ids['organization_id']).to be_nil
      end

      it 'does touch customer after user unassignment' do
        expect { organization.update(member_ids: []) }.to change { customer.reload.updated_at }
      end

      it 'does clear cache of organization after user unassignment' do
        organization.update(member_ids: [])
        expect(organization.reload.attributes_with_association_ids['member_ids']).not_to include(customer.id)
      end

      it 'does touch organization after user unassignment' do
        expect { organization.update(member_ids: []) }.to change { organization.reload.updated_at }
      end
    end

    context 'when member gets added' do
      let(:customer) { create(:customer) }

      before do
        customer.attributes_with_association_ids
        organization.attributes_with_association_ids
      end

      it 'does clear cache of customer after user assignment' do
        organization.update(member_ids: [customer.id])
        expect(customer.reload.attributes_with_association_ids['organization_id']).not_to be_nil
      end

      it 'does touch customer after user assignment' do
        expect { organization.update(member_ids: [customer.id]) }.to change { customer.reload.updated_at }
      end

      it 'does clear cache of organization after user assignment' do
        organization.update(member_ids: [customer.id])
        expect(organization.reload.attributes_with_association_ids['member_ids']).to include(customer.id)
      end

      it 'does touch organization after user assignment' do
        expect { organization.update(member_ids: [customer.id]) }.to change { organization.reload.updated_at }
      end
    end
  end

  describe 'Updating secondary organization members' do
    # the member and organization associations are only part of the attributes for privileged
    # callers, while these examples are about cache invalidation
    around do |example|
      UserInfo.with_system_context { example.run }
    end

    context 'when member gets removed' do
      let(:customer)               { create(:customer, organization: organization) }
      let(:secondary_organization) { create(:organization) }

      before do
        secondary_organization.update(member_ids: [customer.id])

        customer.attributes_with_association_ids
        organization.attributes_with_association_ids
        secondary_organization.attributes_with_association_ids
      end

      it 'does clear cache of customer after user unassignment' do
        secondary_organization.update(member_ids: [])
        expect(customer.reload.attributes_with_association_ids['organization_id']).to be_nil
      end

      it 'does touch customer after user unassignment' do
        expect { secondary_organization.update(member_ids: []) }.to change { customer.reload.updated_at }
      end

      it 'does clear cache of organization after user unassignment' do
        secondary_organization.update(member_ids: [])
        expect(secondary_organization.reload.attributes_with_association_ids['member_ids']).not_to include(customer.id)
      end

      it 'does touch organization after user unassignment' do
        expect { secondary_organization.update(member_ids: []) }.to change { secondary_organization.reload.updated_at }
      end
    end

    context 'when member gets added' do
      let(:customer) { create(:customer, organization: organization) }
      let(:secondary_organization) { create(:organization) }

      before do
        customer.attributes_with_association_ids
        organization.attributes_with_association_ids
        secondary_organization.attributes_with_association_ids
      end

      it 'does clear cache of customer after user assignment' do
        secondary_organization.update(secondary_member_ids: [customer.id])
        expect(customer.reload.attributes_with_association_ids['organization_id']).not_to be_nil
      end

      it 'does touch customer after user assignment' do
        expect { secondary_organization.update(secondary_member_ids: [customer.id]) }.to change { customer.reload.updated_at }
      end

      it 'does clear cache of organization after user assignment' do
        secondary_organization.update(member_ids: [customer.id])
        expect(secondary_organization.reload.attributes_with_association_ids['member_ids']).to include(customer.id)
      end

      it 'does touch organization after user assignment' do
        expect { secondary_organization.update(member_ids: [customer.id]) }.to change { secondary_organization.reload.updated_at }
      end
    end

  end

  describe 'Guarding secondary organization members', :aggregate_failures do
    let(:customer)               { create(:customer, organization: organization) }
    let(:secondary_organization) { create(:organization) }

    %i[<< push append concat].each do |method|
      it "is not allowed to add a member whose primary organization it is via ##{method}" do
        expect { organization.secondary_members.public_send(method, customer) }
          .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Secondary organizations cannot include the primary organization.')
        expect(customer.reload.organizations).to be_empty
      end
    end

    it 'is not allowed to add the same member twice' do
      secondary_organization.secondary_members << customer

      expect { secondary_organization.secondary_members << customer }
        .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Secondary organizations cannot include the same organization twice.')
      expect(customer.reload.organizations).to eq([secondary_organization])
    end

    it 'is not allowed to assign the same member twice' do
      expect { secondary_organization.update!(secondary_member_ids: [customer.id, customer.id]) }
        .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Secondary organizations cannot include the same organization twice.')
      expect(customer.reload.organizations).to be_empty
    end

    it 'allows to add a member with another primary organization' do
      expect { secondary_organization.secondary_members << customer }.not_to raise_error
      expect(customer.reload.organizations).to eq([secondary_organization])
    end

    it 'is not allowed to assign a member whose primary organization it is' do
      expect { organization.secondary_member_ids = [customer.id] }
        .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Secondary organizations cannot include the primary organization.')
      expect(customer.reload.organizations).to be_empty
    end

    it 'allows to move a member from primary to secondary regardless of attribute order' do
      expect { organization.update!(secondary_member_ids: [customer.id], member_ids: []) }.not_to raise_error
      expect(customer.reload).to have_attributes(organization: nil, organizations: [organization])
    end
  end

  describe '#all_members' do
    let!(:primary_user) { create(:user, organization:, organizations: create_list(:organization, 3)) }
    let!(:secondary_user) { create(:user, organization: create(:organization), organizations: [organization]) }

    it 'lists all assigned members' do
      expect(organization.all_members).to contain_exactly(primary_user, secondary_user)
    end
  end

  describe '#destroy_dependent_associations' do
    it 'does create an organization with owner and customer ticket and only destroy the customer ticket', :aggregate_failures do
      organization    = create(:organization)
      user_1          = create(:agent, organization: organization)
      user_1_ticket_1 = create(:ticket, owner: user_1)
      user_2          = create(:customer, organization: organization)
      user_2_ticket_1 = create(:ticket, customer: user_2)

      organization.destroy_dependent_associations
      expect { user_1_ticket_1.reload }.not_to raise_error
      expect { user_2_ticket_1.reload }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  describe '#attributes_with_association_ids' do
    let(:organization)         { create(:organization) }
    let(:foreign_organization) { create(:organization) }
    let(:customer)             { create(:customer, organization: organization) }
    let(:agent)                { create(:agent) }
    let(:secondary_member) do
      create(:customer, organization: foreign_organization, organizations: [organization])
    end

    before { secondary_member }

    it 'includes the secondary member ids without a user context' do
      expect(organization.attributes_with_association_ids['secondary_member_ids']).to eq([secondary_member.id])
    end

    it 'omits the secondary member ids for a customer on a warm cache' do
      # The cache stores the unfiltered attributes and is read before the filtering runs, so the
      # cache hit is a second route to the same hash and must be filtered just as well.
      organization.attributes_with_association_ids

      UserInfo.with_user_id(customer.id) do
        expect(organization.attributes_with_association_ids).not_to include('secondary_member_ids')
      end
    end

    it 'includes the secondary member ids for an agent' do
      UserInfo.with_user_id(agent.id) do
        expect(organization.attributes_with_association_ids['secondary_member_ids']).to eq([secondary_member.id])
      end
    end

    it 'omits the secondary member ids for a customer' do
      UserInfo.with_user_id(customer.id) do
        expect(organization.attributes_with_association_ids).not_to include('secondary_member_ids')
      end
    end
  end

  describe '#assets' do
    let(:organization)         { create(:organization) }
    let(:foreign_organization) { create(:organization) }
    let(:customer)             { create(:customer, organization: organization) }
    let(:agent)                { create(:agent) }
    let(:secondary_member) do
      create(:customer, organization: foreign_organization, organizations: [organization])
    end

    before { secondary_member }

    # Covers every asset consumer at once, including the global search endpoint, which is the only
    # search a customer can reach.
    it 'does not ship a secondary member as an asset to a customer', :aggregate_failures do
      UserInfo.with_user_id(customer.id) do
        assets = organization.assets({})

        expect(assets[described_class.to_app_model][organization.id].keys).to match_array(%w[id name active])
        expect(assets[User.to_app_model]).not_to include(secondary_member.id)
      end
    end

    it 'still ships a secondary member as an asset to an agent' do
      UserInfo.with_user_id(agent.id) do
        expect(organization.assets({})[User.to_app_model]).to include(secondary_member.id)
      end
    end
  end
end

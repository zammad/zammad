# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/can_csv_import_examples'
require 'models/concerns/has_history_examples'
require 'models/concerns/has_search_index_backend_examples'
require 'models/concerns/has_xss_sanitized_note_examples'
require 'models/concerns/has_object_manager_attributes_validation_examples'
require 'models/concerns/has_taskbars_examples'

RSpec.describe Organization, type: :model do
  subject(:organization) { create(:organization) }

  it_behaves_like 'ApplicationModel', can_assets: { associations: :members }
  it_behaves_like 'CanCsvImport', unique_attributes: 'name'
  it_behaves_like 'HasHistory'
  it_behaves_like 'HasSearchIndexBackend', indexed_factory: :organization
  it_behaves_like 'HasXssSanitizedNote', model_factory: :organization
  it_behaves_like 'HasObjectManagerAttributesValidation'
  it_behaves_like 'HasTaskbars'

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
      let!(:user) { create(:customer, organization: organization) }
      let!(:ticket) { create(:ticket, organization: organization, customer: user) }

      it 'checks known refs' do
        refs_organization = Models.references('Organization', organization.id, true)
        expect(refs_organization).to eq(refs_known)
      end

      it 'checks user deletion' do
        organization.destroy
        expect { user.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end

      it 'checks ticket deletion' do
        organization.destroy
        expect { ticket.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end

      describe 'when changes for member_ids' do
        let(:agent1) { create(:agent) }
        let(:agent2) { create(:agent) }
        let(:agent3) { create(:agent) }
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
end

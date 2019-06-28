require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/can_lookup_examples'
require 'models/concerns/has_history_examples'
require 'models/concerns/has_search_index_backend_examples'
require 'models/concerns/has_xss_sanitized_note_examples'
require 'models/concerns/has_object_manager_attributes_validation_examples'

RSpec.describe Organization, type: :model do
  it_behaves_like 'ApplicationModel', can_assets: { associations: :members }
  it_behaves_like 'CanLookup'
  it_behaves_like 'HasHistory'
  it_behaves_like 'HasSearchIndexBackend', indexed_factory: :organization
  it_behaves_like 'HasXssSanitizedNote', model_factory: :organization
  it_behaves_like 'HasObjectManagerAttributesValidation'

  subject(:organization) { create(:organization) }

  describe 'Class methods:' do
    describe '.where_or_cis' do
      it 'finds instance by querying multiple attributes case insensitive' do
        # search for Zammad Foundation
        organizations = described_class.where_or_cis(%i[name note], '%zammad%')
        expect(organizations).not_to be_blank
      end
    end
  end

  describe 'Callbacks, Observers, & Async Transactions -' do
    describe 'Touching associations on update:' do
      let!(:member) { create(:customer_user, organization: organization) }
      let!(:member_ticket) { create(:ticket, customer: member) }

      context 'when basic attributes are updated' do
        it 'touches its members and their tickets' do
          expect { organization.update(name: 'foo') }
            .to change { member.reload.updated_at }
            .and change { member_ticket.reload.updated_at }
        end
      end

      context 'when member associations are added' do
        let(:user) { create(:customer_user) }

        it 'is touched, and touches its other members (but not their tickets)' do
          expect { organization.members.push(user) }
            .to change { organization.reload.updated_at }
            .and change { member.reload.updated_at }
            .and not_change { member_ticket.reload.updated_at }
        end
      end

      context 'with 100+ members' do
        let!(:members) { create_list(:user, 101, organization: organization) }
        let!(:member_ticket) { create(:ticket, customer: members.first) }

        # This _should_ be split into two separate examples,
        # but setup is slow and expensive.
        it 'does not perform any association updates' do
          expect { organization.update(name: 'foo') }
            .to not_change { members.map(&:reload).map(&:updated_at) }
            .and not_change { member_ticket.reload.updated_at }

          expect { organization.members.push(member) }
            .to not_change { organization.reload.updated_at }
            .and not_change { members.map(&:reload).map(&:updated_at) }
        end
      end
    end
  end
end

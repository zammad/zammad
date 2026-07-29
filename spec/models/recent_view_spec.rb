# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe RecentView, type: :model do
  let(:admin)    { create(:admin, groups: [Group.first]) }
  let(:agent)    { create(:agent, groups: [Group.first]) }
  let(:customer) { create(:customer) }
  let(:ticket)   { create(:ticket, owner:, customer:, group: Group.first) }
  let(:tickets)  { create_list(:ticket, 15, owner:, customer:, group: Group.first) }
  let(:owner)    { admin }

  describe '::list' do
    it 'returns a sample of recently viewed objects (e.g., tickets/users/organizations)' do
      tickets.each { |t| described_class.log(t, admin) }

      expect(described_class.list(admin).map(&:o_id)).to include(*tickets.last(10).map(&:id))
    end

    it 'returns up to 10 results by default' do
      tickets.each { |t| described_class.log(t, admin) }

      expect(described_class.list(admin).length).to eq(10)
    end

    context 'with a `limit` argument (optional)' do
      it 'returns up to that number of results' do
        tickets.each { |t| described_class.log(t, admin) }

        expect(described_class.list(admin, 12).length).to eq(12)
      end
    end

    context 'with an `object_name` argument (optional)' do
      it 'includes only the specified model class' do
        described_class.log(ticket, admin)
        described_class.log(Organization.first, admin)

        expect(described_class.list(admin, 10, 'Organization').length).to eq(1)
      end

      it 'does not include merged tickets in results' do
        described_class.log(ticket, admin)
        ticket.update(state: Ticket::State.find_by(name: 'merged'))

        expect(described_class.list(admin, 10, 'Ticket').length).to eq(0)
      end
    end

    it 'does not include duplicate results' do
      5.times { described_class.log(ticket, admin) }

      expect(described_class.list(admin).length).to eq(1)
    end

    it 'orders by most recent view, bumping re-viewed objects to the top' do
      first_ticket, second_ticket = tickets.first(2)

      described_class.log(first_ticket, admin)
      described_class.log(second_ticket, admin)
      described_class.log(first_ticket, admin)

      expect(described_class.list(admin).map(&:o_id)).to eq([first_ticket.id, second_ticket.id])
    end

    it 'does not include deleted tickets in results' do
      described_class.log(ticket, admin)
      ticket.destroy

      expect(described_class.list(admin).length).to eq(0)
    end

    describe 'access privileges' do
      context 'when given user is agent' do
        let(:owner) { agent }

        it 'includes own tickets in results' do
          described_class.log(ticket, agent)

          expect(described_class.list(agent).length).to eq(1)
        end

        it 'does not include tickets without permission in results' do
          described_class.log(ticket, agent)
          ticket.update!(group: create(:group))

          expect(described_class.list(agent).length).to eq(0)
        end

        it 'includes any organizations in results' do
          agent.update(organization: nil)
          described_class.log(Organization.first, agent)

          expect(described_class.list(agent).length).to eq(1)
        end

        it 'includes any users in results' do
          described_class.log(customer, agent)

          expect(described_class.list(agent).map(&:o_id)).to eq([customer.id])
        end
      end

      context 'when given user has an admin permission other than "admin.user"' do
        let(:role)        { create(:role, permissions: [Permission.find_by(name: 'admin.knowledge_base')]) }
        let(:other_admin) { create(:user, roles: [role]) }

        it 'includes any users in results' do
          described_class.log(customer, other_admin)

          expect(described_class.list(other_admin).map(&:o_id)).to eq([customer.id])
        end
      end

      context 'when given user is customer' do
        it 'includes own tickets in results' do
          described_class.log(ticket, customer)

          expect(described_class.list(customer).length).to eq(1)
        end

        it "does not include other customers' tickets in results" do
          described_class.log(ticket, customer)
          ticket.update(customer: User.first)

          expect(described_class.list(customer).length).to eq(0)
        end

        it 'includes own organization in results' do
          customer.update(organization: Organization.first)
          described_class.log(Organization.first, customer)

          expect(described_class.list(customer).length).to eq(1)
        end

        it 'does not include other organizations in results' do
          customer.update(organization: Organization.first)
          described_class.log(Organization.first, customer)
          customer.update(organization: nil)

          expect(described_class.list(customer).length).to eq(0)
        end

        it 'includes own user in results' do
          described_class.log(customer, customer)

          expect(described_class.list(customer).map(&:o_id)).to eq([customer.id])
        end

        it 'includes colleagues of the same organization in results' do
          customer.update(organization: Organization.first)
          colleague = create(:customer, organization: Organization.first)
          described_class.log(colleague, customer)

          expect(described_class.list(customer).map(&:o_id)).to eq([colleague.id])
        end

        it 'does not include users of other organizations in results' do
          customer.update(organization: Organization.first)
          described_class.log(create(:customer, organization: create(:organization)), customer)

          expect(described_class.list(customer).length).to eq(0)
        end
      end
    end
  end

  describe '::user_log_destroy' do
    it 'deletes all RecentView records for a given user' do
      tickets.each { |t| described_class.log(t, admin) }

      expect { described_class.user_log_destroy(admin) }
        .to change { described_class.exists?(created_by_id: admin.id) }.to(false)
    end
  end

  describe '::log' do
    let(:viewed_object) { ticket }

    it 'creates a RecentView entry' do
      expect { described_class.log(viewed_object, admin) }
        .to change(described_class, :count).by(1)
    end

    it 'upserts instead of creating a duplicate when the same object is logged again' do
      described_class.log(viewed_object, admin)

      expect { described_class.log(viewed_object, admin) }
        .not_to change(described_class, :count)
    end

    it 'refreshes the updated_at timestamp on re-log' do
      recent_view = described_class.log(viewed_object, admin)

      expect { described_class.log(viewed_object, admin) }
        .to change { recent_view.reload.updated_at }
    end
  end
end

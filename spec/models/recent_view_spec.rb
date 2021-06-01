# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe RecentView, type: :model do
  let(:admin)    { create(:admin) }
  let(:agent)    { create(:agent) }
  let(:customer) { create(:customer) }
  let(:ticket)   { create(:ticket, owner: owner, customer: customer) }
  let(:tickets)  { create_list(:ticket, 15, owner: owner, customer: customer) }
  let(:owner)    { admin }

  describe '::list' do
    it 'returns a sample of recently viewed objects (e.g., tickets/users/organizations)' do
      tickets.each { |t| described_class.log('Ticket', t.id, admin) }

      expect(described_class.list(admin).map(&:o_id)).to include(*tickets.last(10).map(&:id))
    end

    it 'returns up to 10 results by default' do
      tickets.each { |t| described_class.log('Ticket', t.id, admin) }

      expect(described_class.list(admin).length).to eq(10)
    end

    context 'with a `limit` argument (optional)' do
      it 'returns up to that number of results' do
        tickets.each { |t| described_class.log('Ticket', t.id, admin) }

        expect(described_class.list(admin, 12).length).to eq(12)
      end
    end

    context 'with an `object_name` argument (optional)' do
      it 'includes only the specified model class' do
        described_class.log('Ticket', ticket.id, admin)
        described_class.log('Organization', 1, admin)

        expect(described_class.list(admin, 10, 'Organization').length).to eq(1)
      end

      it 'does not include merged tickets in results' do
        described_class.log('Ticket', ticket.id, admin)
        ticket.update(state: Ticket::State.find_by(name: 'merged'))

        expect(described_class.list(admin, 10, 'Ticket').length).to eq(0)
      end

      it 'does not include removed tickets in results' do
        described_class.log('Ticket', ticket.id, admin)
        ticket.update(state: Ticket::State.find_by(name: 'removed'))

        expect(described_class.list(admin, 10, 'Ticket').length).to eq(0)
      end
    end

    it 'does not include duplicate results' do
      5.times { described_class.log('Ticket', ticket.id, admin) }

      expect(described_class.list(admin).length).to eq(1)
    end

    it 'does not include deleted tickets in results' do
      described_class.log('Ticket', ticket.id, admin)
      ticket.destroy

      expect(described_class.list(admin).length).to eq(0)
    end

    describe 'access privileges' do
      context 'when given user is agent' do
        let(:owner) { agent }

        it 'includes own tickets in results' do
          described_class.log('Ticket', ticket.id, agent)

          expect(described_class.list(agent).length).to eq(1)
        end

        it 'does not include other agents’ tickets in results' do
          described_class.log('Ticket', ticket.id, agent)
          ticket.update(owner: User.first)

          expect(described_class.list(agent).length).to eq(0)
        end

        it 'includes any organizations in results' do
          agent.update(organization: nil)
          described_class.log('Organization', 1, agent)

          expect(described_class.list(agent).length).to eq(1)
        end
      end

      context 'when given user is customer' do
        it 'includes own tickets in results' do
          described_class.log('Ticket', ticket.id, customer)

          expect(described_class.list(customer).length).to eq(1)
        end

        it 'does not include other customers’ tickets in results' do
          described_class.log('Ticket', ticket.id, customer)
          ticket.update(customer: User.first)

          expect(described_class.list(customer).length).to eq(0)
        end

        it 'includes own organization in results' do
          customer.update(organization: Organization.first)
          described_class.log('Organization', 1, customer)

          expect(described_class.list(customer).length).to eq(1)
        end

        it 'does not include other organizations in results' do
          customer.update(organization: Organization.first)
          described_class.log('Organization', 1, customer)
          customer.update(organization: nil)

          expect(described_class.list(customer).length).to eq(0)
        end
      end
    end
  end

  describe '::user_log_destroy' do
    it 'deletes all RecentView records for a given user' do
      create_list(:recent_view, 10, created_by_id: admin.id)

      expect { described_class.user_log_destroy(admin) }
        .to change { described_class.exists?(created_by_id: admin.id) }.to(false)
    end
  end

  describe '::log' do
    let(:viewed_object)          { ticket }
    let(:viewed_object_class_id) { ObjectLookup.by_name(viewed_object.class.name) }

    it 'wraps RecentView.create' do
      expect do
        described_class.log(viewed_object.class.name, viewed_object.id, admin)
      end.to change(described_class, :count).by(1)
    end

    describe 'access privileges' do
      let(:owner) { agent }

      it 'does not create RecentView for records the given user cannot read' do
        ticket.update(owner:        User.first, # read access may come from ticket ownership,
                      customer:     User.first, # customer status,
                      organization: nil)    # organization's 'shared' status,
        agent.update(groups: [])            # and membership in the Ticket's group

        expect do
          described_class.log(viewed_object.class.name, viewed_object.id, agent)
        end.not_to change(described_class, :count)
      end
    end

    context 'when given an invalid object' do
      it 'does not create RecentView for non-existent record' do
        expect do
          described_class.log('User', 99_999_999, admin)
        end.not_to change(described_class, :count)
      end

      it 'does not create RecentView for instance of non-ObjectLookup class' do
        expect do
          described_class.log('Overview', 1, admin)
        end.not_to change(described_class, :count)
      end

      it 'does not create RecentView for instance of non-existent class' do
        expect do
          described_class.log('NonExistentClass', 1, admin)
        end.not_to change(described_class, :count)
      end
    end
  end
end

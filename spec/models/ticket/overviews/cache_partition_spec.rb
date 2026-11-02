# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Overviews::CachePartition, :aggregate_failures do
  subject(:partition) { described_class.new(overview, user) }

  let(:group)         { create(:group) }
  let(:foreign_group) { create(:group) }
  let(:overview)      { create(:overview) }
  let(:closed_state)  { Ticket::State.find_by(name: 'closed') }

  describe '#key' do
    let(:agent_key) { described_class.new(overview, create(:agent, groups: [group])).key }

    context 'with an agent' do
      let(:user) { create(:agent, groups: [group]) }

      it 'is keyed by the overview and read groups only' do
        expect(partition.key).to end_with("groupPermissions:#{[group.id]}-readGroupPermissions:#{[group.id]}")
      end
    end

    context 'with an agent who may see a group in overviews only' do
      let(:user) { create(:agent).tap { |agent| agent.group_names_access_map = { group.name => 'overview' } } }

      it 'does not share the key with agents who may read the group' do
        expect(partition.key).not_to eq(agent_key)
      end
    end

    context 'with an agent who is a customer as well' do
      let(:user) { create(:agent_and_customer, groups: [group]) }

      it 'shares the key with agents of the same groups' do
        expect(partition.key).to eq(agent_key)
      end

      shared_examples 'deciding by the overview condition' do
        context 'with an own ticket outside the groups matching the overview' do
          before { create(:ticket, customer: user, group: foreign_group) }

          it 'is personal and names the own customer access' do
            expect(partition).to be_personal
            expect(partition.key).to end_with("currentUserId:#{user.id}-customerId:#{user.id}")
          end
        end

        context 'with an own ticket outside the groups excluded by the overview' do
          before { create(:ticket, customer: user, group: foreign_group, state: closed_state) }

          it 'shares the key with agents of the same groups' do
            expect(partition).not_to be_personal
            expect(partition.key).to eq(agent_key)
          end
        end
      end

      context 'with a simple condition' do
        include_examples 'deciding by the overview condition'
      end

      context 'with an expert condition' do
        let(:overview) { create(:overview, :condition_expert) }

        include_examples 'deciding by the overview condition'
      end
    end

    context 'with an agent who is a customer in shared organizations' do
      let(:shared_organization)           { create(:organization, shared: true) }
      let(:secondary_shared_organization) { create(:organization, shared: true) }
      let(:user) do
        create(:agent_and_customer, groups: [group], organization: shared_organization,
                                    organizations: [secondary_shared_organization, create(:organization, shared: false)])
      end

      it 'is keyed by the shared organizations' do
        expect(partition.key).to end_with("sharedOrganizations:#{[shared_organization.id, secondary_shared_organization.id].sort}")
      end

      context 'with an own ticket of a shared organization outside the groups' do
        before { create(:ticket, customer: user, group: foreign_group, organization: secondary_shared_organization) }

        it 'is not personal' do
          expect(partition).not_to be_personal
        end
      end

      context 'with an own ticket without organization outside the groups' do
        before { create(:ticket, customer: user, group: foreign_group).update_columns(organization_id: nil) }

        it 'is personal and still keyed by the shared organizations' do
          expect(partition.key).to include("sharedOrganizations:#{[shared_organization.id, secondary_shared_organization.id].sort}")
          expect(partition.key).to end_with("currentUserId:#{user.id}-customerId:#{user.id}")
        end
      end
    end

    context 'with a customer' do
      let(:user) { create(:customer) }

      it 'is keyed by empty group permissions' do
        expect(partition.key).to end_with('groupPermissions:[]-readGroupPermissions:[]')
      end

      context 'with an own ticket matching the overview' do
        before { create(:ticket, customer: user) }

        it 'is personal and names the own customer access' do
          expect(partition.key).to end_with("currentUserId:#{user.id}-customerId:#{user.id}")
        end
      end

      context 'with a shared organization' do
        let(:organization) { create(:organization, shared: true) }
        let(:user)         { create(:customer, organization:) }

        before { create(:ticket, customer: user) }

        it 'shares the key with the other customers of the organization' do
          other_partition = described_class.new(overview, create(:customer, organization:))

          expect(partition).not_to be_personal
          expect(partition.key).to end_with("sharedOrganizations:#{[organization.id]}")
          expect(partition.key).to eq(other_partition.key)
        end
      end
    end

    context 'with an overview referring to the current user' do
      let(:overview) { Overview.find_by(link: 'my_assigned') }
      let(:user)     { create(:agent, groups: [group]) }

      it 'is personal' do
        expect(partition.key).to end_with("currentUserId:#{user.id}")
      end

      context 'with an agent who is a customer as well' do
        let(:user) { create(:agent_and_customer, groups: [group]) }

        it 'names the own customer access, so that the entry is left behind with the customer permission' do
          expect(partition.key).to end_with("currentUserId:#{user.id}-customerId:#{user.id}")

          user.update!(roles: Role.where(name: 'Agent'))
          Auth::RequestCache.clear

          expect(described_class.new(overview, user.reload).key).to end_with("currentUserId:#{user.id}")
        end
      end
    end
  end

  describe '#tickets' do
    let(:user)                 { create(:agent_and_customer, groups: [group], organization:) }
    let(:organization)         { create(:organization, shared: true) }
    let!(:group_ticket)        { create(:ticket, group:) }
    let!(:organization_ticket) { create(:ticket, group: foreign_group, customer: create(:customer, organization:)) }

    it 'returns the tickets of the captured access' do
      expect(partition.tickets).to contain_exactly(group_ticket, organization_ticket)
    end

    context 'when the access changes after the partition was decided' do
      before { partition }

      it 'leaves out an own ticket created outside the shared access' do
        create(:ticket, customer: user, group: foreign_group).update_columns(organization_id: nil)
        expect(partition.tickets).to contain_exactly(group_ticket, organization_ticket)
      end

      it 'leaves out an own ticket moved outside the shared access' do
        create(:ticket, customer: user, group:).update_columns(group_id: foreign_group.id, organization_id: nil)
        expect(partition.tickets).to contain_exactly(group_ticket, organization_ticket)
      end

      it 'leaves out the tickets of a group the user got access to' do
        user.group_names_access_map = { group.name => 'full', foreign_group.name => 'full' }
        create(:ticket, group: foreign_group)
        expect(partition.tickets).to contain_exactly(group_ticket, organization_ticket)
      end

      it 'leaves out the tickets of an organization that got shared' do
        other_organization = create(:organization, shared: false)
        user.update!(organizations: [other_organization])
        create(:ticket, group: foreign_group, customer: create(:customer, organization: other_organization))
        other_organization.update!(shared: true)
        expect(partition.tickets).to contain_exactly(group_ticket, organization_ticket)
      end

      it 'leaves out the tickets of an organization the user was removed from' do
        user.update!(organization: nil)
        expect(partition.tickets).to contain_exactly(group_ticket)
      end

      context 'with an agent who became a customer' do
        let(:overview) { Overview.find_by(link: 'my_assigned') }
        let(:user)     { create(:agent, groups: [group]) }

        it 'leaves out the own tickets outside the shared access' do
          user.update!(roles: Role.where(name: %w[Agent Customer]))
          Auth::RequestCache.clear
          create(:ticket, customer: user, owner: user, group: foreign_group)

          expect(partition.tickets).to be_empty
        end
      end
    end

    context 'with a personal partition' do
      let!(:own_ticket) { create(:ticket, customer: user, group: foreign_group).tap { |ticket| ticket.update_columns(organization_id: nil) } }

      it 'returns the own tickets as well' do
        expect(partition.tickets).to contain_exactly(group_ticket, organization_ticket, own_ticket)
      end
    end
  end

  describe '#readable_tickets' do
    let(:user)               { create(:agent).tap { |agent| agent.group_names_access_map = { group.name => 'full', overview_group.name => 'overview' } } }
    let(:overview_group)     { create(:group) }
    let!(:readable_ticket)   { create(:ticket, group:) }

    before { create(:ticket, group: overview_group) }

    it 'leaves out the tickets of groups the user may see in overviews only' do
      expect(partition.readable_tickets).to contain_exactly(readable_ticket)
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ActivityStreamPolicy::Scope do
  subject(:scope) { described_class.new(user, ActivityStream) }

  describe '#resolve' do
    # Entries about tickets are authorized against the current state of the ticket, so the matrix
    #   below uses an object that is authorized by `permission_id` alone.
    let(:object) { Organization.first }

    let!(:activity_streams) do
      {
        permissionless: {
          grouped:   create(:activity_stream, o: object, permission_id: nil, group_id: Group.first.id),
          groupless: create(:activity_stream, o: object, permission_id: nil, group_id: nil),
        },
        admin:          {
          grouped:   create(:activity_stream, o: object, permission_id: admin_permission.id, group_id: Group.first.id),
          groupless: create(:activity_stream, o: object, permission_id: admin_permission.id, group_id: nil),
        },
        agent:          {
          grouped:   create(:activity_stream, o: object, permission_id: agent_permission.id, group_id: Group.first.id),
          groupless: create(:activity_stream, o: object, permission_id: agent_permission.id, group_id: nil),
        }
      }
    end

    let(:admin_permission) { Permission.find_by(name: 'admin') }
    let(:agent_permission) { Permission.find_by(name: 'ticket.agent') }

    context 'with customer' do
      let(:user) { create(:customer) }

      it 'returns an empty ActiveRecord::Relation (no arrays--must be chainable!)' do
        expect(scope.resolve)
          .to be_empty
          .and be_an(ActiveRecord::Relation)
      end
    end

    context 'with groupless agent' do
      let(:user) { create(:agent, groups: []) }

      it 'returns agent ActivityStreams (w/o permission: nil)' do
        expect(scope.resolve)
          .to contain_exactly(activity_streams[:agent][:groupless])
      end

      it 'does not include groups’ agent ActivityStreams' do
        expect(scope.resolve)
          .not_to include(activity_streams[:agent][:grouped])
      end
    end

    context 'with grouped agent' do
      let(:user) { create(:agent, groups: [Group.first]) }

      it 'returns same ActivityStreams as groupless agent, plus groups’ (WITH permission: nil)' do
        expect(scope.resolve)
          .to contain_exactly(activity_streams[:permissionless][:grouped], *activity_streams[:agent].values)
      end
    end

    context 'with groupless admin' do
      # Why do we need Import Mode?
      # Without it, create(:admin) generates yet another ActivityStream
      let(:user) do
        Setting.set('import_mode', true)
          .then { create(:admin, groups: []) }
          .tap { Setting.set('import_mode', false) }
      end

      it 'returns agent/admin ActivityStreams (w/o permission: nil)' do
        expect(scope.resolve)
          .to contain_exactly(activity_streams[:admin][:groupless], activity_streams[:agent][:groupless])
      end

      it 'does not include groups’ agent ActivityStreams' do
        expect(scope.resolve)
          .not_to include(activity_streams[:admin][:grouped])
      end
    end

    context 'with entries about a ticket' do
      let(:user)                { create(:agent, groups: [group]) }
      let(:group)               { create(:group) }
      let(:inaccessible_group)  { create(:group) }
      let(:ticket)              { create(:ticket, group: group) }
      let(:article)             { create(:ticket_article, ticket: ticket) }
      let!(:ticket_entry)       { create(:activity_stream, o: ticket, permission_id: agent_permission.id, group_id: group.id) }
      let!(:article_entry)      { create(:activity_stream, o: article, permission_id: agent_permission.id, group_id: group.id) }

      it 'returns the entries of the ticket and its article' do
        expect(scope.resolve).to include(ticket_entry, article_entry)
      end

      context 'when the ticket was moved to an inaccessible group' do
        before { ticket.update!(group: inaccessible_group) }

        it 'does not return the entry of the ticket' do
          expect(scope.resolve).not_to include(ticket_entry)
        end

        it 'does not return the entry of its article' do
          expect(scope.resolve).not_to include(article_entry)
        end

        it 'still returns entries about other objects' do
          expect(scope.resolve).to include(activity_streams[:agent][:groupless])
        end
      end

      context 'when the access to the group of the ticket was revoked' do
        before { user.group_names_access_map = {} }

        it 'does not return the entry of the ticket' do
          expect(scope.resolve).not_to include(ticket_entry)
        end

        it 'does not return the entry of its article' do
          expect(scope.resolve).not_to include(article_entry)
        end
      end
    end

    context 'with grouped admin' do
      # Why do we need Import Mode?
      # Without it, create(:admin) generates yet another ActivityStream
      let(:user) do
        Setting.set('import_mode', true)
          .then { create(:admin, groups: [Group.first]) }
          .tap { Setting.set('import_mode', false) }
      end

      it 'returns same ActivityStreams as groupless admin, plus groups’ (WITH permission: nil)' do
        expect(scope.resolve)
          .to contain_exactly(activity_streams[:permissionless][:grouped], *activity_streams[:admin].values, *activity_streams[:agent].values)
      end
    end
  end
end

# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ActivityStreamPolicy::Scope do
  subject(:scope) { described_class.new(user, ActivityStream) }

  describe '#resolve' do
    let!(:activity_streams) do
      {
        permissionless: {
          grouped:   create(:activity_stream, permission_id: nil, group_id: Group.first.id),
          groupless: create(:activity_stream, permission_id: nil, group_id: nil),
        },
        admin:          {
          grouped:   create(:activity_stream, permission_id: admin_permission.id, group_id: Group.first.id),
          groupless: create(:activity_stream, permission_id: admin_permission.id, group_id: nil),
        },
        agent:          {
          grouped:   create(:activity_stream, permission_id: agent_permission.id, group_id: Group.first.id),
          groupless: create(:activity_stream, permission_id: agent_permission.id, group_id: nil),
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
          .to match_array([activity_streams[:agent][:groupless]])
      end

      it 'does not include groups’ agent ActivityStreams' do
        expect(scope.resolve)
          .not_to include([activity_streams[:agent][:grouped]])
      end
    end

    context 'with grouped agent' do
      let(:user) { create(:agent, groups: [Group.first]) }

      it 'returns same ActivityStreams as groupless agent, plus groups’ (WITH permission: nil)' do
        expect(scope.resolve)
          .to match_array([activity_streams[:permissionless][:grouped],
                           *activity_streams[:agent].values])
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
          .to match_array([activity_streams[:admin][:groupless],
                           activity_streams[:agent][:groupless]])
      end

      it 'does not include groups’ agent ActivityStreams' do
        expect(scope.resolve)
          .not_to include([activity_streams[:admin][:grouped]])
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
          .to match_array([activity_streams[:permissionless][:grouped],
                           *activity_streams[:admin].values,
                           *activity_streams[:agent].values])
      end
    end
  end
end

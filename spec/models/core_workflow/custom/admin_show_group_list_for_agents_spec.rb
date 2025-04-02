# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/core_workflow/base'

RSpec.describe CoreWorkflow::Custom::AdminShowGroupListForAgents, mariadb: true, type: :model do
  include_context 'with core workflow base'

  describe 'For Users' do
    context 'when creating' do
      let(:user_agent) { create(:agent) }

      context 'when selected' do
        let(:payload) do
          base_payload.merge(
            'screen'     => 'create',
            'class_name' => 'User',
            'params'     => { 'role_ids' => Role.find_by(name: 'Agent').id.to_s },
          )
        end

        it 'shows the groups list' do
          expect(result[:visibility]['group_ids']).to eq('show')
        end
      end

      context 'when unselected' do
        let(:payload) do
          base_payload.merge(
            'screen'     => 'create',
            'class_name' => 'User',
            'params'     => { 'role_ids' => [Role.find_by(name: 'Customer').to_s] },
          )
        end

        it 'removes the groups list' do
          expect(result[:visibility]['group_ids']).to eq('remove')
        end
      end
    end

    context 'when editing' do
      let(:user_agent) { create(:agent) }

      context 'when selected' do
        let(:payload) do
          base_payload.merge(
            'screen'     => 'edit',
            'class_name' => 'User',
            'params'     => { 'role_ids' => Role.find_by(name: 'Agent').id.to_s },
          )
        end

        it 'shows the groups list' do
          expect(result[:visibility]['group_ids']).to eq('show')
        end
      end

      context 'when unselected' do
        let(:payload) do
          base_payload.merge(
            'screen'     => 'edit',
            'class_name' => 'User',
            'params'     => { 'role_ids' => [Role.find_by(name: 'Customer').to_s] },
          )
        end

        it 'removes the groups list' do
          expect(result[:visibility]['group_ids']).to eq('remove')
        end
      end
    end
  end

  describe 'For Roles' do
    context 'when creating' do
      let(:user_agent) { create(:agent) }

      context 'when selected' do
        let(:payload) do
          base_payload.merge(
            'screen'     => 'create',
            'class_name' => 'Role',
            'params'     => { 'permission_ids' => Permission.find_by(name: 'ticket.agent').id.to_s },
          )
        end

        it 'shows the groups list' do
          expect(result[:visibility]['group_ids']).to eq('show')
        end
      end

      context 'when unselected' do
        let(:payload) do
          base_payload.merge(
            'screen'     => 'create',
            'class_name' => 'Role',
            'params'     => { 'permission_ids' => [Permission.find_by(name: 'ticket.customer').to_s] },
          )
        end

        it 'removes the groups list' do
          expect(result[:visibility]['group_ids']).to eq('remove')
        end
      end
    end

    context 'when editing' do
      let(:user_agent) { create(:agent) }

      context 'when selected' do
        let(:payload) do
          base_payload.merge(
            'screen'     => 'edit',
            'class_name' => 'Role',
            'params'     => { 'permission_ids' => Permission.find_by(name: 'ticket.agent').id.to_s },
          )
        end

        it 'shows the groups list' do
          expect(result[:visibility]['group_ids']).to eq('show')
        end
      end

      context 'when unselected' do
        let(:payload) do
          base_payload.merge(
            'screen'     => 'edit',
            'class_name' => 'Role',
            'params'     => { 'permission_ids' => [Permission.find_by(name: 'ticket.customer').to_s] },
          )
        end

        it 'removes the groups list' do
          expect(result[:visibility]['group_ids']).to eq('remove')
        end
      end
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormUpdater::Updater::Ticket::BulkEdit) do
  subject(:resolved_result) do
    described_class.new(
      context:         context,
      relation_fields: relation_fields,
      meta:            meta,
      data:            data,
      id:              nil
    )
  end

  let(:group)   { create(:group) }
  let(:user)    { create(:agent, groups: [group]) }
  let(:tickets) { create_list(:ticket, 5, group: group) }
  let(:context) { { current_user: user } }
  let(:meta)    { { initial: true, form_id: SecureRandom.uuid } }
  let(:data)    { {} }

  let(:relation_fields) do
    [
      {
        name:     'group_id',
        relation: 'Group',
      },
      {
        name:     'owner_id',
        relation: 'User',
      },
    ]
  end

  describe '#authorized?' do
    it 'is authorized for agents' do
      expect(resolved_result.authorized?).to be true
    end

    context 'with customer user' do
      let(:user) { create(:customer) }

      it 'is not authorized for customers' do
        expect(resolved_result.authorized?).to be false
      end
    end

    context 'with admin-only user' do
      let(:user) { create(:user, roles: [Role.find_by(name: 'Admin')]) }

      it 'is not authorized' do
        expect(resolved_result.authorized?).to be false
      end
    end
  end

  context 'when filtering users for owners' do
    let(:new_group)          { create(:group) }
    let(:agents_with_access) { create_list(:agent, 3, groups: [group, new_group]) }
    let(:agents_wo_access)   { create_list(:agent, 3, groups: [group]) }

    let(:meta) do
      {
        additional_data: {
          'entityIds' => tickets.map { |ticket| Gql::ZammadSchema.id_from_object(ticket) },
        },
      }
    end

    before do
      agents_with_access && agents_wo_access
    end

    context 'when no group_id is given in data' do
      it 'returns all users from the current group' do
        expect(resolved_result.resolve[:fields]['owner_id'][:options]).to include(
          { value: agents_with_access[0].id, label: agents_with_access[0].fullname },
          { value: agents_with_access[1].id, label: agents_with_access[1].fullname },
          { value: agents_with_access[2].id, label: agents_with_access[2].fullname },
          { value: agents_wo_access[0].id, label: agents_wo_access[0].fullname },
          { value: agents_wo_access[1].id, label: agents_wo_access[1].fullname },
          { value: agents_wo_access[2].id, label: agents_wo_access[2].fullname },
        )
      end

    end

    context 'when group_id is given in data' do
      let(:data) { { 'group_id' => new_group.id } }

      it 'returns given group users only' do
        expect(resolved_result.resolve[:fields]['owner_id'][:options]).to include(
          { value: agents_with_access[0].id, label: agents_with_access[0].fullname },
          { value: agents_with_access[1].id, label: agents_with_access[1].fullname },
          { value: agents_with_access[2].id, label: agents_with_access[2].fullname },
        ).and not_include(
          { value: agents_wo_access[0].id, label: agents_wo_access[0].fullname },
          { value: agents_wo_access[1].id, label: agents_wo_access[1].fullname },
          { value: agents_wo_access[2].id, label: agents_wo_access[2].fullname },
        )
      end
    end

    context 'with enrichOwnerOptions in additional_data' do
      let(:meta) do
        {
          additional_data: {
            'enrichOwnerOptions' => true,
            'entityIds'          => tickets.map { |ticket| Gql::ZammadSchema.id_from_object(ticket) },
          },
        }
      end

      it 'includes user objects in owner options' do
        expect(resolved_result.resolve[:fields]['owner_id'][:options]).to include(
          include(
            value:  user.id,
            label:  user.fullname,
            object: include(
              '__typename' => 'User',
              'id'         => Gql::ZammadSchema.id_from_object(user),
              'active'     => user.active,
              'email'      => user.email,
              'firstname'  => user.firstname,
              'image'      => nil,
              'lastname'   => user.lastname,
              'mobile'     => user.mobile,
              'phone'      => user.phone,
              'source'     => user.source,
              'vip'        => user.vip,
            )
          ),
        )
      end
    end
  end

  context 'when passing different types of ticket selection' do
    context 'with entityIds in additional_data' do
      let(:meta) do
        {
          additional_data: {
            'entityIds' => tickets.map { |ticket| Gql::ZammadSchema.id_from_object(ticket) },
          },
        }
      end

      it 'adds ticket_ids to payload params' do
        payload = resolved_result.send(:perform_payload)

        expect(payload['params']['ticket_ids']).to eq(tickets.map(&:id).join(','))
      end
    end

    context 'with overviewId in additional_data' do
      let(:overview) { create(:overview, condition: { 'ticket.group_id' => { 'operator' => 'is', 'value' => [group.id] } }) }

      let(:meta) do
        {
          additional_data: {
            'overviewId' => Gql::ZammadSchema.id_from_object(overview),
          },
        }
      end

      before do
        tickets
      end

      it 'resolves ticket_ids from overview and adds to payload params' do
        payload = resolved_result.send(:perform_payload)

        expect(payload['params']['ticket_ids']).to eq(tickets.reverse.map(&:id).join(','))
      end
    end

    context 'with searchQuery in additional_data', searchindex: true do
      let(:meta) do
        {
          additional_data: {
            'searchQuery' => "group_id:#{group.id}",
          },
        }
      end

      before do
        tickets
        searchindex_model_reload([Ticket])
      end

      it 'resolves ticket_ids from search query and adds to payload params' do
        payload = resolved_result.send(:perform_payload)

        expect(payload['params']['ticket_ids']).to eq(tickets.reverse.map(&:id).join(','))
      end
    end
  end
end

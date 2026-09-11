# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CollectionUpdateJob, type: :job do
  let(:session_user) { create(:admin) }
  let(:sessions)     { { 'client-1' => { user: { 'id' => session_user.id } } } }
  let(:messages)     { [] }

  before do
    allow(Sessions).to receive(:list).and_return(sessions)
    allow(Sessions).to receive(:send) { |client_id, data| messages.push(data.merge(client_id:)) }
  end

  describe 'sensitive values' do
    let(:collection) do
      messages
        .find { |message| message[:event] == 'resetCollection' }
        .dig(:data, :Webhook)
        .find { |elem| elem['id'] == webhook.id }
    end

    let(:asset) do
      messages
        .find { |message| message[:event] == 'loadAssets' }
        .dig(:data, :Webhook, webhook.id)
    end

    before do
      webhook

      described_class.perform_now('Webhook')
    end

    context 'with configured authentication' do
      let(:webhook) { create(:webhook, signature_token: 'some_token', basic_auth_password: 'some_password', bearer_token: 'some_token') }

      it 'masks sensitive fields in the pushed collection' do
        expect(collection).to include(
          'signature_token'     => SensitiveParamsHelper::SENSITIVE_MASK,
          'basic_auth_password' => SensitiveParamsHelper::SENSITIVE_MASK,
          'bearer_token'        => SensitiveParamsHelper::SENSITIVE_MASK
        )
      end

      it 'masks sensitive fields in the pushed assets' do
        expect(asset).to include(
          'signature_token'     => SensitiveParamsHelper::SENSITIVE_MASK,
          'basic_auth_password' => SensitiveParamsHelper::SENSITIVE_MASK,
          'bearer_token'        => SensitiveParamsHelper::SENSITIVE_MASK
        )
      end
    end

    context 'without configured authentication' do
      let(:webhook) { create(:webhook) }

      it 'does not mask unset sensitive fields' do
        expect(collection).to include(
          'signature_token'     => nil,
          'basic_auth_password' => nil,
          'bearer_token'        => nil
        )
      end
    end
  end

  # Webhook is the only pushed model with sensitive attributes, so the plain path needs its own coverage.
  describe 'model without sensitive attributes' do
    let(:group) { create(:group) }

    before do
      group

      described_class.perform_now('Group')
    end

    it 'pushes the plain attributes' do
      collection = messages
        .find { |message| message[:event] == 'resetCollection' }
        .dig(:data, :Group)

      expect(collection).to include(include('id' => group.id, 'name' => group.name))
    end
  end

  describe 'collection push permission' do
    before do
      create(:webhook)

      described_class.perform_now('Webhook')
    end

    context 'with an admin session' do
      it 'pushes the webhooks' do
        expect(messages).to include(include(event: 'resetCollection'))
      end
    end

    context 'with a non-admin session' do
      let(:session_user) { create(:agent) }

      it 'pushes nothing' do
        expect(messages).to be_empty
      end
    end
  end

  # Models without a collection_push_permission reach every session, so the assets field scope is
  #   the only thing keeping their non-public attributes from a customer. The job has no user
  #   context of its own, so it must render the payload for the recipient's assets level.
  describe 'assets field scope' do
    let(:collection) do
      messages
        .find { |message| message[:event] == 'resetCollection' }
        .dig(:data, model.to_sym)
        .find { |elem| elem['id'] == record.id }
    end

    let(:asset) do
      messages
        .find { |message| message[:event] == 'loadAssets' }
        .dig(:data, model.to_sym, record.id)
    end

    before do
      record

      described_class.perform_now(model)
    end

    context 'with a Group' do
      let(:model)  { 'Group' }
      let(:record) { create(:group, note: 'Internal note', users: [create(:agent)]) }

      context 'with a customer session' do
        let(:session_user) { create(:customer) }

        it 'pushes the collection without the unauthorized attributes' do
          expect(collection.keys).to match_array(%w[id name name_last follow_up_possible reopen_time_in_days active parent_id])
        end

        it 'pushes the assets without the unauthorized attributes' do
          expect(asset.keys).to match_array(%w[id name name_last follow_up_possible reopen_time_in_days active parent_id])
        end

        it 'discloses neither the note nor the group members' do
          expect(collection).not_to include('note', 'user_ids')
        end
      end

      context 'with an agent session' do
        let(:session_user) { create(:agent) }

        it 'pushes the full collection' do
          expect(collection).to include('note' => record.note, 'user_ids' => record.user_ids)
        end

        it 'pushes the full assets' do
          expect(asset).to include('note' => record.note, 'user_ids' => record.user_ids)
        end
      end

      context 'with an admin session' do
        it 'pushes the full collection' do
          expect(collection).to include('note' => record.note, 'user_ids' => record.user_ids)
        end
      end
    end

    context 'with a Role' do
      let(:model)  { 'Role' }
      let(:record) { create(:role, note: 'Internal note') }

      context 'with a customer session' do
        let(:session_user) { create(:customer) }

        it 'pushes the collection without the unauthorized attributes' do
          expect(collection.keys).to match_array(%w[id name group_ids permission_ids active])
        end

        it 'anonymizes the name' do
          expect(collection).to include('name' => "Role_#{record.id}")
        end
      end

      context 'with an agent session' do
        let(:session_user) { create(:agent) }

        it 'pushes the full collection' do
          expect(collection).to include('name' => record.name, 'note' => record.note)
        end
      end
    end

    context 'with sessions of different levels' do
      let(:model)  { 'Group' }
      let(:record) { create(:group, note: 'Internal note') }

      let(:customer) { create(:customer) }
      let(:sessions) do
        {
          'admin-client'    => { user: { 'id' => session_user.id } },
          'customer-client' => { user: { 'id' => customer.id } },
        }
      end

      let(:collections) do
        messages
          .select { |message| message[:event] == 'resetCollection' }
          .to_h { |message| [message[:client_id], message.dig(:data, :Group).find { |elem| elem['id'] == record.id }] }
      end

      it 'sends the admin session the full payload' do
        expect(collections['admin-client']).to include('note' => record.note)
      end

      it 'sends the customer session the filtered payload' do
        expect(collections['customer-client']).not_to include('note')
      end
    end

    # The push carries the created_by/updated_by users of every record along with it, so the same
    #   audience question applies to them.
    context 'with the users bundled into the assets' do
      let(:model)  { 'Group' }
      let(:record) { create(:group) }

      let(:bundled_user) do
        messages
          .find { |message| message[:event] == 'loadAssets' }
          .dig(:data, :User, record.created_by_id)
      end

      context 'with a customer session' do
        let(:session_user) { create(:customer) }

        it 'pushes them without the unauthorized attributes' do
          expect(bundled_user.keys).to match_array(%w[id firstname lastname image image_source active])
        end
      end

      context 'with an agent session' do
        let(:session_user) { create(:agent) }

        it 'pushes them in full' do
          expect(bundled_user).to include('login' => User.find(record.created_by_id).login)
        end
      end
    end

    context 'with a session of a no longer existing user' do
      let(:model)    { 'Group' }
      let(:record)   { create(:group) }
      let(:sessions) { { 'client-1' => { user: { 'id' => 99_999_999 } } } }

      it 'pushes nothing' do
        expect(messages).to be_empty
      end
    end
  end

  # Every example above drives sessions of distinct levels, so none of them exercises the reuse
  #   of an already built payload. This is a sibling rather than a nested context because the
  #   scan has to be watched before the job runs.
  describe 'sessions that share a level' do
    let(:session_user) { create(:customer) }
    let(:other)        { create(:customer) }
    let(:sessions) do
      {
        'customer-1' => { user: { 'id' => session_user.id } },
        'customer-2' => { user: { 'id' => other.id } },
      }
    end

    before do
      create(:group)

      allow(Group).to receive(:reorder).and_call_original

      described_class.perform_now('Group')
    end

    it 'pushes to every session' do
      expect(messages.pluck(:client_id).uniq).to contain_exactly('customer-1', 'customer-2')
    end

    it 'builds the payload once per level rather than once per session' do
      expect(Group).to have_received(:reorder).once
    end
  end
end

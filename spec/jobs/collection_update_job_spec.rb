# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CollectionUpdateJob, type: :job do
  let(:session_user) { create(:admin) }
  let(:messages)     { [] }

  before do
    allow(Sessions).to receive(:list).and_return({ 'client-1' => { user: { 'id' => session_user.id } } })
    allow(Sessions).to receive(:send) { |_client_id, data| messages.push(data) }
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
end

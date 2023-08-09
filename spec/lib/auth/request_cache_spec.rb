# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Auth::RequestCache do
  let(:user) { create(:agent) }

  context 'when user has permission' do
    let(:permission) { 'ticket.agent' }

    it 'does cache permissions' do
      instance_spy = instance_spy(described_class, permission_cache: {}, permissions?: true)

      allow(described_class).to receive(:instance).and_return(instance_spy)

      described_class.permissions?(user, permission)
      described_class.permissions?(user, permission)

      expect(instance_spy).to have_received(:permissions?).with(user, permission).once
    end
  end

  context 'when user has no permission' do
    let(:permission) { 'ticket.customer' }

    it 'does cache permissions' do
      instance_spy = instance_spy(described_class, permission_cache: {}, permissions?: false)

      allow(described_class).to receive(:instance).and_return(instance_spy)

      described_class.permissions?(user, permission)
      described_class.permissions?(user, permission)

      expect(instance_spy).to have_received(:permissions?).with(user, permission).once
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Cti::Log::QueueFilter do
  subject(:queues) { described_class.with_current_user(user).execute }

  let(:user)  { create(:agent, phone: phone) }
  let(:phone) { '' }

  def configure_notify_map(notify_map)
    cti_config = Setting.get('cti_config')
    cti_config[:notify_map] = notify_map
    Setting.set('cti_config', cti_config)
  end

  it 'requires a current user' do
    expect { described_class.execute }.to raise_error(%r{Current user is required})
  end

  it 'does not limit the caller log without a notify map' do
    expect(queues).to be_nil
  end

  context 'with a notify map' do
    before do
      configure_notify_map([
                             { queue: 'queue1', user_ids: [user.id.to_s] },
                             { queue: 'queue2', user_ids: [create(:agent).id.to_s] },
                           ])
    end

    it 'limits the caller log to the queues the user is mapped to' do
      expect(queues).to eq(['queue1'])
    end

    context 'when the user has a phone number' do
      let(:phone) { '+49 30 609811112' }

      it 'lets the calls to the own phone number through as well' do
        expect(queues).to eq(%w[queue1 4930609811112])
      end
    end

    context 'when the user is mapped to no queue and has no phone' do
      before { configure_notify_map([{ queue: 'queue2', user_ids: [create(:agent).id.to_s] }]) }

      it 'limits the caller log to nothing' do
        expect(queues).to eq([])
      end
    end
  end
end

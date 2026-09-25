# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Cti::Log::List do
  subject(:list) { described_class.with_current_user(user).execute }

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

  it 'lists newest first' do
    older = travel_to(2.minutes.ago) { create(:cti_log) }
    newer = travel_to(1.minute.ago) { create(:cti_log) }

    expect(list).to eq([newer, older])
  end

  context 'without a notify map' do
    let!(:logs) do
      [create(:cti_log, queue: 'queue1'), create(:cti_log, queue: 'queue2'), create(:cti_log, queue: nil)]
    end

    it 'lists every call' do
      expect(list).to match_array(logs)
    end
  end

  context 'with a notify map' do
    let!(:own_queue_log) { create(:cti_log, queue: 'queue1') }
    let!(:own_phone_log) { create(:cti_log, queue: '4930609811112') }

    before do
      create(:cti_log, queue: 'queue2')
      configure_notify_map([
                             { queue: 'queue1', user_ids: [user.id.to_s] },
                             { queue: 'queue2', user_ids: [create(:agent).id.to_s] },
                           ])
    end

    it 'lists only the calls of the queues the user is mapped to' do
      expect(list).to contain_exactly(own_queue_log)
    end

    context 'when the user has a phone number' do
      let(:phone) { '+49 30 609811112' }

      it 'lists the calls to the own phone number as well' do
        expect(list).to contain_exactly(own_queue_log, own_phone_log)
      end
    end

    context 'when the user is mapped to no queue and has no phone' do
      before { configure_notify_map([{ queue: 'queue2', user_ids: [create(:agent).id.to_s] }]) }

      it 'lists nothing' do
        expect(list).to be_empty
      end
    end
  end

  # The old caller log stops at cti_config[:view_limit] (default 60); this one pages instead.
  context 'with more entries than the view limit' do
    before { create_list(:cti_log, Cti::Log.view_limit + 1) }

    it 'is not capped' do
      expect(list.count).to eq(Cti::Log.view_limit + 1)
    end
  end
end

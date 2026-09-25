# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Cti::Log::DoneUpdate do
  subject(:service) { described_class.with_current_user(user).execute(log:, done:) }

  let(:user) { create(:agent) }
  let(:log)  { create(:cti_log, done: false) }
  let(:done) { true }

  def configure_notify_map(notify_map)
    cti_config = Setting.get('cti_config')
    cti_config[:notify_map] = notify_map
    Setting.set('cti_config', cti_config)
  end

  it 'requires a current user' do
    expect { described_class.execute(log:, done:) }.to raise_error(%r{Current user is required})
  end

  it 'marks the call as handled' do
    expect { service }.to change { log.reload.done }.from(false).to(true)
  end

  it 'returns the call' do
    expect(service).to eq(log)
  end

  context 'when the call is already handled' do
    let(:log)  { create(:cti_log, done: true) }
    let(:done) { false }

    it 'marks it as not handled' do
      expect { service }.to change { log.reload.done }.from(true).to(false)
    end
  end

  context 'with a notify map' do
    before do
      configure_notify_map([
                             { queue: 'queue1', user_ids: [user.id.to_s] },
                             { queue: 'queue2', user_ids: [create(:agent).id.to_s] },
                           ])
    end

    context 'when the call is in one of the user\'s queues' do
      let(:log) { create(:cti_log, queue: 'queue1') }

      it 'marks the call' do
        expect { service }.to change { log.reload.done }.to(true)
      end
    end

    context 'when the call is in another queue' do
      let(:log) { create(:cti_log, queue: 'queue2') }

      it 'rejects the change and leaves the call alone', :aggregate_failures do
        expect { service }.to raise_error(Exceptions::Forbidden, 'The call is not in your caller log.')
        expect(log.reload).not_to be_done
      end
    end
  end
end

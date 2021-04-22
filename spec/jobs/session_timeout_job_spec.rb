require 'rails_helper'

RSpec.describe SessionTimeoutJob, type: :job do
  before do
    create(:active_session, user: user)
  end

  context 'with timeout admin' do
    let(:user) { create(:admin) }

    before do
      Setting.set('session_timeout', { admin: 30.minutes.to_s })
    end

    it 'does kill the session' do
      travel_to 1.hour.from_now
      expect { described_class.perform_now }.to change(ActiveRecord::SessionStore::Session, :count).by(-1)
    end

    it 'does not kill the session' do
      travel_to 1.minute.from_now
      expect { described_class.perform_now }.to change(ActiveRecord::SessionStore::Session, :count).by(0)
    end
  end

  context 'with timeout ticket.agent' do
    let(:user) { create(:agent) }

    before do
      Setting.set('session_timeout', { 'ticket.agent': 30.minutes.to_s })
    end

    it 'does kill the session' do
      travel_to 1.hour.from_now
      expect { described_class.perform_now }.to change(ActiveRecord::SessionStore::Session, :count).by(-1)
    end

    it 'does not kill the session' do
      travel_to 1.minute.from_now
      expect { described_class.perform_now }.to change(ActiveRecord::SessionStore::Session, :count).by(0)
    end
  end

  context 'with timeout ticket.customer' do
    let(:user) { create(:customer) }

    before do
      Setting.set('session_timeout', { 'ticket.customer': 30.minutes.to_s })
    end

    it 'does kill the session' do
      travel_to 1.hour.from_now
      expect { described_class.perform_now }.to change(ActiveRecord::SessionStore::Session, :count).by(-1)
    end

    it 'does not kill the session' do
      travel_to 1.minute.from_now
      expect { described_class.perform_now }.to change(ActiveRecord::SessionStore::Session, :count).by(0)
    end
  end

  context 'with timeout agent and customer' do
    let(:user) { create(:agent_and_customer) }

    before do
      Setting.set('session_timeout', { 'ticket.customer': 1.second.to_s, 'ticket.agent': 2.hours.to_s })
    end

    it 'does kill the session' do
      travel_to 1.day.from_now
      expect { described_class.perform_now }.to change(ActiveRecord::SessionStore::Session, :count).by(-1)
    end

    it 'does not kill the session' do
      travel_to 1.hour.from_now
      expect { described_class.perform_now }.to change(ActiveRecord::SessionStore::Session, :count).by(0)
    end
  end

  context 'with timeout default' do
    let(:user) { create(:customer) }

    before do
      Setting.set('session_timeout', { default: 30.minutes.to_s })
    end

    it 'does kill the session' do
      travel_to 1.hour.from_now
      expect { described_class.perform_now }.to change(ActiveRecord::SessionStore::Session, :count).by(-1)
    end

    it 'does not kill the session' do
      travel_to 1.minute.from_now
      expect { described_class.perform_now }.to change(ActiveRecord::SessionStore::Session, :count).by(0)
    end
  end
end

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::Device::Delete do
  subject(:service_result) { described_class.with_current_user(agent).execute(device:) }

  let(:agent)  { create(:agent) }
  let(:device) { create(:user_device, user_id: agent.id) }

  def create_sessions(count, device)
    create_list(:session, count,
                data: {
                  'user_id'                 => device.user_id,
                  'user_device_fingerprint' => device.fingerprint,
                  'persistent'              => true
                })
  end

  context 'with given user having one device and one related session' do
    before { create_sessions(1, device) }

    it 'destroys the device and the related session' do
      expect { service_result }.to change(UserDevice, :count).by(-1).and change(Session, :count).by(-1)
    end
  end

  context 'with given user having one device and multiple related sessions' do
    before { create_sessions(3, device) }

    it 'destroys the device and all the related sessions' do
      expect { service_result }.to change(UserDevice, :count).by(-1).and change(Session, :count).by(-3)
    end
  end

  context 'with other users having devices and sessions' do
    before do
      create_sessions(3, device)

      create_list(:agent, 2).each do |other_agent|
        create_sessions(2, create(:user_device, user_id: other_agent.id))
      end
    end

    it 'destroys only the selected device and its related sessions' do
      expect { service_result }.to change(UserDevice, :count).by(-1).and change(Session, :count).by(-3)
    end
  end

  context 'with other users having a device with the identical fingerprint' do
    before do
      create_sessions(3, device)

      create_list(:agent, 2).each do |other_agent|
        create_sessions(2, create(:user_device, user_id: other_agent.id, fingerprint: device.fingerprint))
      end
    end

    it 'destroys only the selected device and its related sessions' do
      expect { service_result }.to change(UserDevice, :count).by(-1).and change(Session, :count).by(-3)
    end
  end
end

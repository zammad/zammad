# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::Device::Delete do
  subject(:service) { described_class.new(user: agent, device: device) }

  context 'with given user having one device and one related session' do
    let(:agent)  { create(:agent) }
    let(:device) { create(:user_device, user_id: agent.id) }

    it 'destroys the device and the related session' do
      create(:session,
             data: {
               'user_id'                 => agent.id,
               'user_device_fingerprint' => device.fingerprint,
               'persistent'              => true
             })

      expect { service.execute }.to change(UserDevice, :count).by(-1).and change(Session, :count).by(-1)
    end
  end

  context 'with given user having multiple devices and multiple related session' do
    let(:agent)   { create(:agent) }
    let(:device)  { create(:user_device, user_id: agent.id) }

    let(:agents)  { create_list(:agent, Faker::Number.within(range: 2..42)) } # rubocop:disable Zammad/FakerUnique
    let(:devices) do
      agents.map do |agent|
        create(:user_device, user_id: agent.id)
      end
    end

    it 'destroys only the selected device and all the related session' do
      sessions = Faker::Number.within(range: 2..42) # rubocop:disable Zammad/FakerUnique
      create_list(:session, sessions,
                  data: {
                    'user_id'                 => agent.id,
                    'user_device_fingerprint' => device.fingerprint,
                    'persistent'              => true
                  })

      devices.each do |device|
        create_list(:session, Faker::Number.within(range: 2..42), # rubocop:disable Zammad/FakerUnique
                    data: {
                      'user_id'                 => device.user_id,
                      'user_device_fingerprint' => device.fingerprint,
                      'persistent'              => true
                    })
      end

      expect { service.execute }.to change(UserDevice, :count).by(-1).and change(Session, :count).by(-1 * sessions)
    end
  end
end

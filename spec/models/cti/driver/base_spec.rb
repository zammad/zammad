# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Cti::Driver::Base do
  subject!(:driver) { described_class.new(mapping: {}, params: params, config: config ) }

  let(:direction) { 'in' }
  let(:event) { 'newCall' }
  let(:config) { {} }
  let(:params) { { 'direction' => direction, 'event' => event } }

  describe '.direction_check' do
    context 'for in direction' do
      subject!(:direction) { 'in' }

      it 'returns nil' do
        expect(driver.direction_check).to be(nil)
      end
    end

    context 'for out direction' do
      subject!(:direction) { 'out' }

      it 'returns nil' do
        expect(driver.direction_check).to be(nil)
      end
    end

    context 'for not existing direction' do
      subject!(:direction) { 'not existing' }

      it 'returns invalid_direction action' do
        expect(driver.direction_check).to eq({ action: 'invalid_direction', params: { 'direction' => 'not existing', 'event' => 'newCall' } })
      end
    end
  end

  describe '.reject_check' do
    context 'with reject number in from param and matching caller_id' do
      let(:params) { { 'direction' => direction, 'event' => event, 'from' => '1234' } }
      let(:config) do
        {
          inbound: {
            block_caller_ids: [ { caller_id: '1234' } ],
          },
        }
      end

      it 'returns reject action' do
        expect(driver.reject_check).to eq(action: 'reject')
      end
    end

    context 'with reject number in from param and matching caller_id but wrong direction' do
      let(:params) { { 'direction' => direction, 'event' => event, 'from' => '1234' } }
      let(:direction) { 'out' }
      let(:config) do
        {
          inbound: {
            block_caller_ids: [ { caller_id: '1234' } ],
          },
        }
      end

      it 'returns nil' do
        expect(driver.reject_check).to be(nil)
      end
    end

    context 'with reject number in from param but not matching caller_id' do
      let(:params) { { 'direction' => direction, 'event' => event, 'from' => '12345' } }
      let(:direction) { 'in' }
      let(:config) do
        {
          inbound: {
            block_caller_ids: [ { caller_id: '1234' } ],
          },
        }
      end

      it 'returns nil' do
        expect(driver.reject_check).to be(nil)
      end
    end
  end

  describe '.push_open_ticket_screen_recipient' do
    context 'with direct number in answeringNumber params' do
      let(:params) { { 'direction' => direction, 'event' => event, answeringNumber: user.phone } }
      let!(:user) { create(:agent, phone: '1234567') }

      it 'returns related user' do
        expect(driver.push_open_ticket_screen_recipient).to eq(user)
      end
    end

    context 'with not existing direct number in answeringNumber params' do
      let(:params) { { 'direction' => direction, 'event' => event, answeringNumber: '98765421' } }
      let!(:user) { create(:agent, phone: '1234567') }

      it 'returns nil' do
        expect(driver.push_open_ticket_screen_recipient).to be(nil)
      end
    end

    context 'with real phone number in answeringNumber params' do
      let(:params) { { 'direction' => direction, 'event' => event, answeringNumber: '491711000001' } }
      let!(:user) { create(:agent, phone: '0171 1000001') }

      it 'returns related user' do
        expect(driver.push_open_ticket_screen_recipient).to eq(user)
      end
    end

    context 'with user in upcase in params' do
      let(:params) { { 'direction' => direction, 'event' => event, user: user.login.upcase } }
      let!(:user) { create(:agent) }

      it 'returns related user' do
        expect(driver.push_open_ticket_screen_recipient).to eq(user)
      end
    end

    context 'with user_id in params' do
      let(:params) { { 'direction' => direction, 'event' => event, user_id: user.id } }
      let!(:user) { create(:agent) }

      it 'returns related user' do
        expect(driver.push_open_ticket_screen_recipient).to eq(user)
      end
    end

  end

end

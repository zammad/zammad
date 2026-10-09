# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::PushSubscription::Deliver do
  subject(:deliver) { described_class.execute(subscription:, message:) }

  let!(:subscription) { create(:push_subscription, endpoint: 'https://fcm.googleapis.com/fcm/send/1') }
  let(:message)       { '{"title":"Printer is on fire"}' }

  def push_error(klass)
    klass.new(Struct.new(:body).new('error'), 'push.example.com')
  end

  before do
    allow(WebPush).to receive(:payload_send)
    allow(Rails.logger).to receive(:error)
  end

  it 'sends the message signed with the VAPID keys of this instance' do
    deliver

    expect(WebPush).to have_received(:payload_send).with(
      hash_including(
        message:  message,
        endpoint: subscription.endpoint,
        p256dh:   subscription.p256dh,
        auth:     subscription.auth,
        vapid:    {
          subject:     "https://#{Setting.get('fqdn')}",
          public_key:  Setting.get('web_push_vapid_public_key'),
          private_key: Setting.get('web_push_vapid_private_key'),
        },
      )
    )
  end

  it 'uses no proxy by default' do
    deliver

    expect(WebPush).to have_received(:payload_send).with(hash_excluding(:proxy))
  end

  context 'with a proxy configured' do
    before do
      Setting.set('proxy', 'proxy.example.com:3128')
      Setting.set('proxy_username', 'user')
      Setting.set('proxy_password', 'p@ss')
    end

    it 'passes the proxy including its credentials' do
      deliver

      expect(WebPush).to have_received(:payload_send).with(hash_including(proxy: 'http://user:p%40ss@proxy.example.com:3128'))
    end

    context 'when the push service is on the no-proxy list' do
      before { Setting.set('proxy_no', 'localhost,fcm.googleapis.com') }

      it 'connects directly' do
        deliver

        expect(WebPush).to have_received(:payload_send).with(hash_excluding(:proxy))
      end
    end
  end

  context 'when the subscription points to an unknown push service' do
    before { subscription.update_column(:endpoint, 'https://169.254.169.254/latest/meta-data') }

    it 'removes the subscription without sending', :aggregate_failures do
      expect { deliver }.to change(PushSubscription, :count).by(-1)

      expect(WebPush).not_to have_received(:payload_send)
    end
  end

  context 'when the push service rejects the subscription for good' do
    [WebPush::ExpiredSubscription, WebPush::InvalidSubscription].each do |error_class|
      context "with #{error_class.name}" do
        before { allow(WebPush).to receive(:payload_send).and_raise(push_error(error_class)) }

        it 'removes the subscription' do
          expect { deliver }.to change(PushSubscription, :count).by(-1)
        end
      end
    end
  end

  context 'when the delivery fails because of the configuration of this instance' do
    {
      'the push service rejects the VAPID signature' => -> { push_error(WebPush::Unauthorized) },
      'the VAPID key cannot be read'                 => -> { OpenSSL::PKey::PKeyError.new('invalid curve name') },
    }.each do |description, error|
      context "when #{description}" do
        before { allow(WebPush).to receive(:payload_send).and_raise(instance_exec(&error)) }

        it 'logs the failure and keeps the subscription', :aggregate_failures do
          expect { deliver }.not_to change(PushSubscription, :count)

          expect(Rails.logger).to have_received(:error)
        end
      end
    end

    {
      'the proxy address has no port'        => 'proxy.example.com',
      'the proxy host is no valid host name' => 'proxy example.com:3128',
    }.each do |description, proxy|
      context "when #{description}" do
        before { Setting.set('proxy', proxy) }

        it 'logs the failure and keeps the subscription without sending', :aggregate_failures do
          expect { deliver }.not_to change(PushSubscription, :count)

          expect(WebPush).not_to have_received(:payload_send)
          expect(Rails.logger).to have_received(:error)
        end
      end
    end
  end

  context 'when the delivery fails temporarily' do
    {
      'the push service has a server error' => -> { push_error(WebPush::PushServiceError) },
      'the push service limits the rate'    => -> { push_error(WebPush::TooManyRequests) },
      'the push service does not answer'    => -> { Net::OpenTimeout.new },
      'the network is unreachable'          => -> { Errno::ENETUNREACH.new },
    }.each do |description, error|
      context "when #{description}" do
        before { allow(WebPush).to receive(:payload_send).and_raise(instance_exec(&error)) }

        it 'keeps the subscription and raises an error to retry on', :aggregate_failures do
          expect { deliver }.to raise_error(described_class::TemporaryError)

          expect(PushSubscription).to exist(subscription.id)
        end
      end
    end
  end
end

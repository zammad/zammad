# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe PushSubscription, type: :model do
  subject(:push_subscription) { create(:push_subscription) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:endpoint) }
  it { is_expected.to validate_presence_of(:p256dh) }
  it { is_expected.to validate_presence_of(:auth) }
  it { is_expected.to validate_uniqueness_of(:endpoint) }

  it 'accepts the keys a browser generates' do
    expect(push_subscription).to be_valid
  end

  it 'rejects an endpoint without TLS' do
    push_subscription.endpoint = 'http://fcm.googleapis.com/fcm/send/1'

    expect(push_subscription).not_to be_valid
  end

  context 'with the endpoint of a push service' do
    %w[
      https://web.push.apple.com/QGuQyavXutnMH-8zd2nvc2Y
      https://fcm.googleapis.com/fcm/send/dpH5lCsTSSM
      https://jmt17.google.com/fcm/send/dpH5lCsTSSM
      https://updates.push.services.mozilla.com/wpush/v2/gAAAAABk
      https://wns2-par02p.notify.windows.com/w/?token=BQYAAAB
      https://WEB.PUSH.APPLE.COM./QGuQyavXutnMH-8zd2nvc2Y
    ].each do |endpoint|
      it "accepts #{endpoint}" do
        push_subscription.endpoint = endpoint

        expect(push_subscription).to be_valid
      end
    end
  end

  context 'with an endpoint outside the known push services' do
    %w[
      https://169.254.169.254/latest/meta-data
      https://10.0.0.5/push
      https://localhost/push
      https://push.example.com/subscription/1
      https://web.push.apple.com.evil.example/push
      https://evilweb.push.apple.com/push
      https://web.push.apple.com@evil.example/push
      https://googleapis.com/fcm/send/1
      https://www.google.com/fcm/send/1
    ].each do |endpoint|
      it "rejects #{endpoint}" do
        push_subscription.endpoint = endpoint

        expect(push_subscription).not_to be_valid
      end
    end
  end

  it 'rejects an endpoint that is no URL' do
    push_subscription.endpoint = 'not a url'

    expect(push_subscription).not_to be_valid
  end

  it 'rejects a client key of the wrong length' do
    push_subscription.p256dh = Base64.urlsafe_encode64(SecureRandom.random_bytes(32), padding: false)

    expect(push_subscription).not_to be_valid
  end

  it 'rejects an authentication secret that is not base64url encoded' do
    push_subscription.auth = 'not base64!'

    expect(push_subscription).not_to be_valid
  end

  it 'is removed together with its user' do
    user = push_subscription.user

    expect { user.destroy! }.to change(described_class, :count).by(-1)
  end
end

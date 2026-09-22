# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::SendPasswordChangeNotification do
  subject(:service_result) { described_class.execute(user:, **options) }

  let(:user)    { create(:user) }
  let(:options) { {} }

  before { allow(NotificationFactory::Mailer).to receive(:notification) }

  describe '#execute' do
    it 'notifies the user' do
      service_result

      expect(NotificationFactory::Mailer).to have_received(:notification).with(
        template: 'password_change',
        user:     user,
        objects:  {
          user: user,
        }
      )
    end

    context 'with a separate recipient' do
      let(:recipient) { create(:user) }
      let(:options)   { { recipient: } }

      it 'sends to the recipient' do
        service_result

        expect(NotificationFactory::Mailer).to have_received(:notification).with(hash_including(user: recipient))
      end

      it 'renders the template for the changed user' do
        service_result

        expect(NotificationFactory::Mailer).to have_received(:notification).with(hash_including(objects: { user: user }))
      end
    end
  end
end

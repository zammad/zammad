# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe NotificationMailerJob, type: :job do
  let(:user)  { create(:user) }
  let(:token) { create(:token, action: 'PasswordReset', user: user, persistent: false) }

  let(:objects)  { { token: token, user: user } }
  let(:url_path) { 'desktop/reset-password/verify/' }

  describe '#perform' do
    it 'delivers the notification' do
      message = nil

      allow(NotificationFactory::Mailer).to receive(:deliver) do |params|
        message = params[:body]
      end

      described_class.perform_now(template: 'password_reset', user: user, objects: objects, url_path: url_path)

      expect(message).to include "<a href=\"http://zammad.example.com/#{url_path}#{token.token}\">"
    end

    context 'when an object got removed before the job runs' do
      before do
        allow(Rails.logger).to receive(:info)
        allow(NotificationFactory::Mailer).to receive(:deliver)
      end

      it 'discards the job without delivering', :aggregate_failures do
        serialized_job = described_class.new(template: 'password_reset', user: user, objects: objects, url_path: url_path).serialize
        token.destroy!

        expect { ActiveJob::Base.execute(serialized_job) }.not_to raise_error
        expect(NotificationFactory::Mailer).not_to have_received(:deliver)
        expect(Rails.logger).to have_received(:info).with(%r{Discarding job})
      end
    end
  end
end

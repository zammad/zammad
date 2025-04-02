# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TicketArticleCommunicateEmailJob, type: :job do
  describe '#perform' do
    context 'for an email article' do
      let(:article)        { create(:ticket_article, type_name: 'email') }
      let(:recipient_list) { [article.to, article.cc].compact_blank.join(',') }

      before { allow(Rails.logger).to receive(:info) }

      # What we _really_ want is to expect an email to be sent.
      # So why are we testing log messages instead?
      #
      # Because so far, our attempts to test email dispatch have either
      # a) been closely tied to implementation, with lots of ugly mock objects; or
      # b) had to test faraway classes like Channel::Driver::Imap.
      #
      # In other words, this test is NOT set in stone, and very open to improvement.
      it 'records outgoing email dispatch to Rails log' do
        described_class.perform_now(article.id)

        expect(Rails.logger)
          .to have_received(:info)
          .with("Send email to: '#{recipient_list}' (from #{article.from})")
      end
    end

    # https://github.com/zammad/zammad/issues/5523
    context 'when channel is deactivated' do
      let(:email_address) { create(:email_address, channel:) }
      let(:group)   { create(:group, email_address:) }
      let(:channel) { create(:channel, active: false) }
      let(:ticket)  { create(:ticket, group:) }
      let(:article) { create(:ticket_article, :outbound_email, ticket:) }

      before do
        allow(Rails.logger).to receive(:error)

        email_address && ticket
        channel.update!(group:)
      end

      it 'does not send email' do
        expect_any_instance_of(Channel).not_to receive(:deliver)

        described_class.perform_now(article.id)
      end

      it 'logs an error' do
        described_class.perform_now(article.id)

        expect(Rails.logger)
          .to have_received(:error)
          .with("Channel defined for email address id '#{email_address.id}' is not active!")
      end
    end
  end
end

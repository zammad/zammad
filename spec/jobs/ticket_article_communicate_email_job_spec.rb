# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TicketArticleCommunicateEmailJob, type: :job do
  describe '#perform' do
    context 'for an email article' do
      let(:article) { create(:ticket_article, type_name: 'email') }
      let(:recipient_list) { [article.to, article.cc].reject(&:blank?).join(',') }

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
  end
end

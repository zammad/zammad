# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ContentTranslationJob, type: :job do
  let(:article)       { create(:ticket_article) }
  let(:target_locale) { 'de-de' }

  describe '#lock_key' do
    it 'locks per object and target locale' do
      job = described_class.new
      allow(job).to receive(:arguments).and_return([article, target_locale])

      expect(job.lock_key).to eq("ContentTranslationJob/Ticket::Article/#{article.id}/de-de")
    end
  end

  describe '#perform' do
    def perform
      described_class.perform_now(article, target_locale, service: 'Service::ContentTranslation::TicketArticle')
    end

    before do
      allow(Gql::Subscriptions::Ticket::Article::TranslationUpdates).to receive(:trigger_for)
    end

    context 'when the service returns a translation' do
      let(:analytics_run) { create(:ai_analytics_run) }

      let(:service_result) do
        Service::ContentTranslation::Base::Result[
          content:       '<p>Hallo Welt.</p>',
          backend:       'ai',
          translated:    true,
          fresh:         true,
          analytics_run:,
        ]
      end

      before do
        allow(Service::ContentTranslation::TicketArticle).to receive(:execute).and_return(service_result)
      end

      it 'asks the given service and forces the translation' do
        perform

        expect(Service::ContentTranslation::TicketArticle)
          .to have_received(:execute).with(object: article, target_locale:, force: true, background: false, regeneration_of: nil)
      end

      it 'triggers the subscription with the translation' do
        perform

        expect(Gql::Subscriptions::Ticket::Article::TranslationUpdates)
          .to have_received(:trigger_for)
          .with(
            article,
            target_locale,
            {
              translation:         { content: '<p>Hallo Welt.</p>', backend: 'ai', translated: true },
              ai_analytics_run_id: analytics_run.id,
            }
          )
      end
    end

    context 'when the service returns nothing' do
      before do
        allow(Service::ContentTranslation::TicketArticle).to receive(:execute).and_return(nil)
      end

      it 'triggers the subscription without a translation' do
        perform

        expect(Gql::Subscriptions::Ticket::Article::TranslationUpdates)
          .to have_received(:trigger_for).with(article, target_locale, {})
      end
    end

    context 'when the service raises' do
      before do
        allow(Rails.logger).to receive(:error)
        allow(Service::ContentTranslation::TicketArticle).to receive(:execute).and_raise(StandardError, 'some error')
      end

      it 'triggers the subscription with the error' do
        perform

        expect(Gql::Subscriptions::Ticket::Article::TranslationUpdates)
          .to have_received(:trigger_for)
          .with(article, target_locale, { error: { message: 'some error', exception: 'StandardError' } })
      end
    end
  end
end

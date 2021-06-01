# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TriggerWebhookJob, type: :job do

  let(:endpoint) { 'http://api.example.com/webhook' }
  let(:token) { 's3cr3t-t0k3n' }
  let(:webhook) { create(:webhook, endpoint: endpoint, signature_token: token) }
  let(:trigger) do
    create(:trigger,
           perform: {
             'notification.webhook' => { 'webhook_id' => webhook.id }
           })
  end

  context 'when serialized model argument gets deleted' do

    subject!(:job) { described_class.perform_later(trigger, ticket, article) }

    let(:ticket) { create(:ticket) }
    let(:article) { create(:'ticket/article') }

    shared_examples 'handle deleted argument models' do
      it 'raises no error' do
        expect { ActiveJob::Base.execute job.serialize }.not_to raise_error
      end

      it "doesn't perform request" do
        allow(UserAgent).to receive(:post)
        ActiveJob::Base.execute job.serialize
        expect(UserAgent).not_to have_received(:post)
      end
    end

    context 'when Trigger gets deleted' do
      before { trigger.destroy! }

      include_examples 'handle deleted argument models'
    end

    context 'when Ticket gets deleted' do
      before { ticket.destroy! }

      include_examples 'handle deleted argument models'
    end

    context 'when Article gets deleted' do
      before { article.destroy! }

      include_examples 'handle deleted argument models'
    end
  end

  describe '#perform' do
    subject(:perform) { described_class.perform_now(trigger, ticket, article) }

    let(:payload_ticket) { TriggerWebhookJob::RecordPayload.generate(ticket) }
    let(:payload_article) { TriggerWebhookJob::RecordPayload.generate(article) }

    let!(:ticket) { create(:ticket) }
    let!(:article) { create(:'ticket/article') }

    let(:response_status) { 200 }
    let(:payload) do
      {
        ticket:  payload_ticket,
        article: payload_article,
      }
    end

    let(:headers) do
      {
        'Content-Type'     => 'application/json',
        'User-Agent'       => 'Zammad User Agent',
        'X-Zammad-Trigger' => trigger.name,
      }
    end

    let(:response_body) do
      {}.to_json
    end

    before do
      stub_request(:post, endpoint).to_return(status: response_status, body: response_body)

      perform
    end

    context 'with trigger token configured' do
      it 'includes X-Hub-Signature header' do
        expect(WebMock).to have_requested(:post, endpoint)
          .with( body: payload, headers: headers )
          .with { |req| req.headers['X-Zammad-Delivery'].is_a?(String) }
          .with { |req| req.headers['X-Hub-Signature'].is_a?(String) }
      end
    end

    context 'without trigger token configured' do
      let(:token) { nil }

      it "doesn't include X-Hub-Signature header" do
        expect(WebMock).to have_requested(:post, endpoint)
          .with( body: payload, headers: headers )
          .with { |req| req.headers['X-Zammad-Delivery'].is_a?(String) }
          .with { |req| !req.headers.key?('X-Hub-Signature') }
      end
    end

    context 'when response is not JSON' do

      let(:response_body) { 'Thanks!' }

      it 'succeeds anyway' do
        expect(described_class).not_to have_been_enqueued
      end
    end

    context "when request doesn't succeed" do
      let(:response_status) { 404 }

      it 'enqueues job again' do
        expect(described_class).to have_been_enqueued
      end
    end
  end
end

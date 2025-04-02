# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TriggerWebhookJob, type: :job do

  let(:endpoint) { 'http://api.example.com/webhook' }
  let(:token)    { 's3cr3t-t0k3n' }
  let(:webhook)  { create(:webhook, endpoint: endpoint, signature_token: token) }
  let(:trigger) do
    create(:trigger,
           perform: {
             'notification.webhook' => { 'webhook_id' => webhook.id }
           })
  end

  context 'when serialized model argument gets deleted' do

    subject!(:job) do
      described_class.perform_later(
        trigger,
        ticket,
        article,
        changes:        nil,
        user_id:        nil,
        execution_type: nil,
        event_type:     nil,
      )
    end

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
    subject(:perform) do
      described_class.perform_now(
        trigger,
        ticket,
        article,
        changes:        nil,
        user_id:        nil,
        execution_type: nil,
        event_type:     nil,
      )
    end

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
        'Content-Type'     => 'application/json; charset=utf-8',
        'User-Agent'       => 'Zammad User Agent',
        'X-Zammad-Trigger' => trigger.name,
      }
    end

    let(:response_body) do
      {}.to_json
    end

    let(:response_headers) { {} }

    before do
      stub_request(:post, endpoint).to_return(headers: response_headers, status: response_status, body: response_body)

      perform
    end

    context 'with trigger token configured' do
      it 'includes X-Hub-Signature header' do
        expect(WebMock).to have_requested(:post, endpoint)
          .with(body: payload, headers: headers)
          .with { |req| req.headers['X-Zammad-Delivery'].is_a?(String) }
          .with { |req| req.headers['X-Hub-Signature'].is_a?(String) }
      end
    end

    context 'without trigger token configured' do
      let(:token) { nil }

      it "doesn't include X-Hub-Signature header" do
        expect(WebMock).to have_requested(:post, endpoint)
          .with(body: payload, headers: headers)
          .with { |req| req.headers['X-Zammad-Delivery'].is_a?(String) }
          .with { |req| !req.headers.key?('X-Hub-Signature') }
      end
    end

    context 'with HTTP BasicAuth configured' do
      let(:webhook) { create(:webhook, endpoint: endpoint, basic_auth_username: 'user', basic_auth_password: 'passw0rd') }

      it 'generates a request with Authorization header' do
        expect(WebMock).to have_requested(:post, endpoint)
          .with(body: payload, headers: headers)
          .with { |req| req.headers['Authorization'] == "Basic #{Base64.strict_encode64('user:passw0rd')}" }
      end
    end

    context 'without HTTP BasicAuth configured' do
      let(:webhook)  { create(:webhook, endpoint: endpoint) }

      it 'generates a request without Authorization header' do
        expect(WebMock).to have_requested(:post, endpoint)
          .with(body: payload, headers: headers)
          .with { |req| !req.headers.key?('Authorization') }
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

    context 'when response is a redirect' do
      let(:response_status)  { 301 }
      let(:response_headers) { { Location: 'http://redirect.target/' } }

      it 'enqueues job again due to redirect exception', :aggregate_failures do
        expect(described_class).to have_been_enqueued
        expect(HttpLog.last.response).to include('code' => 0, 'content' => '')
      end
    end

    context 'with different payloads' do
      subject(:perform) do
        described_class.perform_now(
          trigger,
          ticket,
          article,
          changes:        nil,
          user_id:        nil,
          execution_type: 'trigger',
          event_type:     'info',
        )
      end

      let(:webhook)                  { create(:webhook, endpoint: endpoint, customized_payload: customized_payload, custom_payload: custom_payload, pre_defined_webhook_type: pre_defined_webhook_type) }
      let(:customized_payload)       { false }
      let(:custom_payload)           { nil }
      let(:pre_defined_webhook_type) { nil }

      def pre_defined_webhook_payload
        tracks = { ticket: ticket, article: article }
        data = {
          event:   {
            type:      'info',
            execution: 'trigger',
            changes:   nil,
            user_id:   nil,
          },
          webhook: webhook
        }

        TriggerWebhookJob::CustomPayload.tracks.select { |t| t.respond_to?(:generate) }.each do |klass|
          klass.generate(tracks, data)
        end

        predefined_payload = TriggerWebhookJob::CustomPayload::Track::PreDefinedWebhook.payload('Mattermost')
        TriggerWebhookJob::CustomPayload.generate(predefined_payload, tracks)
      end

      shared_examples 'including correct payload' do
        it 'includes correct payload' do
          expect(WebMock).to have_requested(:post, endpoint)
            .with(body: payload, headers: headers)
        end
      end

      context 'with non-customized payload' do
        it_behaves_like 'including correct payload'

        context 'with pre-defined webhook' do
          let(:webhook) { create(:mattermost_webhook, endpoint: endpoint) }
          let(:payload) { pre_defined_webhook_payload }

          it_behaves_like 'including correct payload'
        end
      end

      context 'with customized payload' do
        let(:customized_payload) { true }
        let(:custom_payload)     { '{"ticket":"\#{ticket.title}"}' }
        let(:payload) do
          {
            ticket: ticket.title,
          }
        end

        it_behaves_like 'including correct payload'

        context 'with pre-defined webhook' do
          let(:webhook) { create(:mattermost_webhook, endpoint: endpoint, customized_payload:, custom_payload:) }

          it_behaves_like 'including correct payload'
        end

        context 'with empty custom payload' do
          let(:custom_payload) { nil }
          let(:payload) do
            {
              ticket:  payload_ticket,
              article: payload_article,
            }
          end

          it_behaves_like 'including correct payload'

          context 'with pre-defined webhook' do
            let(:webhook) { create(:mattermost_webhook, endpoint: endpoint) }
            let(:payload) { pre_defined_webhook_payload }

            it_behaves_like 'including correct payload'
          end
        end
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Webhooks::NotificationJob, type: :job do
  describe '#perform' do
    subject(:perform!) do
      described_class.perform_now(
        webhook_id:    webhook.id,
        resource_type: 'ticket',
        resource_id:   ticket.id,
        event:         'created'
      )
    end

    let!(:ticket) { create(:ticket) }
    let(:webhook) { create(:webhook) }
    let(:webhook_status) { 200 }
    let(:webhook_body) do
      {
        webhook_id:    webhook.id,
        event:         'created',
        resource_type: 'ticket',
        resource_id:   ticket.id
      }
    end
    let(:webhook_headers) do
      {
        'Content-Type' => 'application/json',
        'User-Agent'   => "Zammad/#{Version.get}"
      }
    end

    before do
      stub_request(:post, webhook.url).to_return(status: webhook_status)
    end

    it 'sends a post request to webhook URL' do
      perform!

      expect(WebMock).to have_requested(:post, webhook.url)
        .with(body: webhook_body, headers: webhook_headers)
    end

    context 'when the webhook endpoint fail' do
      let(:webhook_status) { 404 }

      it 'retries on exception' do
        perform!

        expect(described_class).to have_been_enqueued
      end
    end
  end
end

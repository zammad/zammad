require 'rails_helper'

RSpec.describe Webhooks::NotificationJob, type: :job do
  describe '#perform' do
    let(:webhook) { create(:webhook) }
    let!(:ticket) { create(:ticket) }
    let(:webhook_status) { 200 }

    before do
      stub_request(:post, webhook.url).to_return(status: webhook_status)
    end

    it 'sends a post request to webhook URL' do
      described_class.perform_now(
        webhook_id:    webhook.id,
        resource_type: 'ticket',
        resource_id:   ticket.id,
        event:         'created'
      )

      expect(WebMock).to have_requested(:post, webhook.url)
        .with(
          body:    {
            webhook_id:    webhook.id,
            event:         'created',
            resource_type: 'ticket',
            resource_id:   ticket.id
          },
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent'   => "Zammad/#{Version.get}"
          }
        )
    end

    context 'when the webhook endpoint fail' do
      let(:webhook_status) { 404 }

      it 'retries on exception' do
        described_class.perform_now(
          webhook_id:    webhook.id,
          resource_type: 'ticket',
          resource_id:   ticket.id,
          event:         'created'
        )

        expect(described_class).to have_been_enqueued
      end
    end
  end
end

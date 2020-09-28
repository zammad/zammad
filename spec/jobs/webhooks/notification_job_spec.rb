require 'rails_helper'

RSpec.describe Webhooks::NotificationJob, type: :job do
  describe '#perform' do
    subject(:perform!) do
      described_class.perform_now(
        ticket_id:   ticket.id,
        trigger_id:  trigger.id,
        delivery_id: delivery_id
      )
    end

    let!(:ticket) { create(:ticket) }
    let(:trigger) do
      create(:trigger,
             perform: {
               'notification.webhook' => {
                 endpoint: 'http://api.mycompany.com/webhook/support',
                 token:    token
               }
             })
    end

    let(:delivery_id) { 'de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9' }
    let(:token) { 's3cr3t-t0k3n' }

    let(:webhook_status) { 200 }
    let(:webhook_headers) do
      {
        'Content-Type'      => 'application/json',
        'User-Agent'        => "Zammad/#{Version.get}",
        'X-Zammad-Trigger'  => trigger.name,
        'X-Zammad-Delivery' => delivery_id
      }
    end

    before do
      stub_request(:post, 'http://api.mycompany.com/webhook/support').to_return(status: webhook_status)
    end

    context 'with trigger token configured' do
      it 'sends a post request to webhook URL with signature in header' do
        perform!

        expect(WebMock).to have_requested(:post, 'http://api.mycompany.com/webhook/support')
          .with(body: ticket.attributes_with_association_names, headers: webhook_headers.merge( 'X-Hub-Signature' => OpenSSL::HMAC.hexdigest('sha1', token, 'verified'), 'X-Zammad-Delivery' => delivery_id))
      end
    end

    context 'without trigger token configured' do
      let(:token) { nil }

      it 'sends a post request to webhook URL without signature in header' do
        perform!

        expect(WebMock).to have_requested(:post, 'http://api.mycompany.com/webhook/support')
          .with(body: ticket.attributes_with_association_names, headers: webhook_headers)
      end
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
